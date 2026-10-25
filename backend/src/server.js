import crypto from 'node:crypto';
import { pathToFileURL } from 'node:url';

import 'dotenv/config';
import { GoogleGenAI } from '@google/genai';
import express from 'express';
import rateLimit from 'express-rate-limit';
import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import helmet from 'helmet';
import { z } from 'zod';

import { signConversationToken, verifyConversationToken } from './conversation-token.js';
import { KALASAG_SYSTEM_INSTRUCTION } from './safety-policy.js';

const requestSchema = z.object({
  message: z.string().trim().min(1).max(1200),
  locale: z.string().trim().min(2).max(16).default('en-PH'),
  previousInteractionId: z.string().trim().min(20).max(1024).optional(),
});

export function loadConfig(environment = process.env) {
  const config = {
    nodeEnv: environment.NODE_ENV ?? 'development',
    apiKey: environment.GEMINI_API_KEY ?? '',
    model: environment.GEMINI_MODEL ?? 'gemini-3.5-flash-lite',
    signingSecret: environment.CONVERSATION_SIGNING_SECRET ?? '',
    projectId: environment.GOOGLE_CLOUD_PROJECT ?? '',
    port: Number(environment.PORT ?? 8787),
    allowUnauthenticatedDev: environment.ALLOW_UNAUTHENTICATED_DEV === 'true',
  };
  if (!config.apiKey) throw new Error('GEMINI_API_KEY is required.');
  if (config.signingSecret.length < 32) {
    throw new Error('CONVERSATION_SIGNING_SECRET must contain at least 32 characters.');
  }
  if (!Number.isInteger(config.port) || config.port < 1 || config.port > 65535) {
    throw new Error('PORT must be a valid TCP port.');
  }
  if (config.nodeEnv === 'production' && config.allowUnauthenticatedDev) {
    throw new Error('Unauthenticated development mode is forbidden in production.');
  }
  if (!config.allowUnauthenticatedDev && !config.projectId) {
    throw new Error('GOOGLE_CLOUD_PROJECT is required when authentication is enforced.');
  }
  return config;
}

function initializeFirebase(projectId) {
  if (getApps().length) return;
  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  initializeApp(
    serviceAccountJson
      ? {
          credential: cert(JSON.parse(serviceAccountJson)),
          projectId,
        }
      : { projectId },
  );
}

export function mapGeminiError(error) {
  const status = Number(error?.status ?? error?.code ?? 500);
  const raw = `${error?.message ?? ''}`.toLowerCase();
  if (status === 429 && raw.includes('quota')) {
    return { status: 429, code: 'quota_exceeded', message: 'Gemini quota is exhausted.' };
  }
  if (status === 429) {
    return { status: 429, code: 'rate_limited', message: 'Too many Gemini requests.' };
  }
  if (raw.includes('safety') || raw.includes('blocked') || raw.includes('prohibited')) {
    return { status: 400, code: 'safety_blocked', message: 'The request was blocked for safety.' };
  }
  if (status === 400) {
    return { status: 400, code: 'invalid_request', message: 'Gemini rejected the request.' };
  }
  if (status === 401 || status === 403) {
    return { status: 503, code: 'provider_auth', message: 'Gemini provider authentication failed.' };
  }
  return { status: 503, code: 'provider_unavailable', message: 'Gemini is temporarily unavailable.' };
}

async function withTimeout(promise, milliseconds) {
  let timer;
  try {
    return await Promise.race([
      promise,
      new Promise((_, reject) => {
        timer = setTimeout(() => reject(new Error('provider_timeout')), milliseconds);
      }),
    ]);
  } finally {
    clearTimeout(timer);
  }
}

export function createApp({ config, ai, verifyIdToken } = {}) {
  const resolvedConfig = config ?? loadConfig();
  const client = ai ?? new GoogleGenAI({ apiKey: resolvedConfig.apiKey });
  if (!resolvedConfig.allowUnauthenticatedDev && !verifyIdToken) {
    initializeFirebase(resolvedConfig.projectId);
  }
  const tokenVerifier =
    verifyIdToken ?? ((token) => getAuth().verifyIdToken(token, true));

  const app = express();
  app.disable('x-powered-by');
  app.use(helmet());
  app.use(express.json({ limit: '16kb', strict: true }));
  app.use(
    '/v1/chat',
    rateLimit({
      windowMs: 60_000,
      limit: 12,
      standardHeaders: 'draft-8',
      legacyHeaders: false,
    }),
  );

  app.get('/health', (_request, response) => {
    response.json({ status: 'ok', model: resolvedConfig.model });
  });

  app.post('/v1/chat', async (request, response) => {
    const requestId = crypto.randomUUID();
    const startedAt = Date.now();
    let uid = 'unknown';
    try {
      if (resolvedConfig.allowUnauthenticatedDev) {
        uid = 'local-development';
      } else {
        const match = /^Bearer\s+(.+)$/i.exec(request.headers.authorization ?? '');
        if (!match) {
          return response.status(401).json({
            error: { code: 'unauthorized', message: 'A valid identity token is required.' },
          });
        }
        const decoded = await tokenVerifier(match[1]);
        uid = decoded.uid;
      }

      const parsed = requestSchema.safeParse(request.body);
      if (!parsed.success) {
        return response.status(400).json({
          error: { code: 'invalid_request', message: 'The chat request is invalid.' },
        });
      }

      const previousInteractionId = parsed.data.previousInteractionId
        ? verifyConversationToken({
            token: parsed.data.previousInteractionId,
            uid,
            secret: resolvedConfig.signingSecret,
          })
        : undefined;

      const interaction = await withTimeout(
        client.interactions.create({
          model: resolvedConfig.model,
          input: parsed.data.message,
          system_instruction: `${KALASAG_SYSTEM_INSTRUCTION}\nUser locale: ${parsed.data.locale}.`,
          previous_interaction_id: previousInteractionId,
          generation_config: {
            max_output_tokens: 900,
            temperature: 0.2,
          },
          safety_settings: [
            { type: 'harassment', threshold: 'block_medium_and_above' },
            { type: 'hate_speech', threshold: 'block_medium_and_above' },
            { type: 'sexually_explicit', threshold: 'block_medium_and_above' },
            { type: 'dangerous_content', threshold: 'block_medium_and_above' },
          ],
        }),
        22_000,
      );
      const text = `${interaction.output_text ?? ''}`.trim();
      if (!interaction.id || !text) {
        throw Object.assign(new Error('empty_response'), { status: 502 });
      }
      const conversationToken = signConversationToken({
        interactionId: interaction.id,
        uid,
        secret: resolvedConfig.signingSecret,
      });
      console.info(
        JSON.stringify({
          requestId,
          uid,
          outcome: 'success',
          durationMs: Date.now() - startedAt,
          model: resolvedConfig.model,
        }),
      );
      return response.json({ text: text.slice(0, 12_000), interactionId: conversationToken });
    } catch (error) {
      const mapped = error?.message === 'invalid_context'
        ? { status: 400, code: 'invalid_context', message: 'Conversation context is invalid or expired.' }
        : error?.message === 'provider_timeout'
        ? { status: 504, code: 'timeout', message: 'Gemini timed out.' }
        : mapGeminiError(error);
      console.warn(
        JSON.stringify({
          requestId,
          uid,
          outcome: mapped.code,
          durationMs: Date.now() - startedAt,
        }),
      );
      return response.status(mapped.status).json({ error: mapped });
    }
  });

  app.use((_request, response) => {
    response.status(404).json({ error: { code: 'not_found', message: 'Route not found.' } });
  });
  return app;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const config = loadConfig();
  createApp({ config }).listen(config.port, '0.0.0.0', () => {
    console.info(JSON.stringify({ event: 'server_started', port: config.port, model: config.model }));
  });
}
