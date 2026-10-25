import assert from 'node:assert/strict';
import test from 'node:test';

import { signConversationToken, verifyConversationToken } from '../src/conversation-token.js';
import { createApp, loadConfig, mapGeminiError } from '../src/server.js';

const secret = 'test-secret-with-more-than-32-characters';

test('conversation tokens are user-bound and expire', () => {
  const token = signConversationToken({ interactionId: 'interaction-1', uid: 'user-1', secret, now: 1000 });
  assert.equal(
    verifyConversationToken({ token, uid: 'user-1', secret, now: 2000 }),
    'interaction-1',
  );
  assert.throws(() => verifyConversationToken({ token, uid: 'user-2', secret, now: 2000 }));
  assert.throws(() =>
    verifyConversationToken({ token, uid: 'user-1', secret, now: 1000 + 86_400_001 }),
  );
});

test('production cannot enable unauthenticated development mode', () => {
  assert.throws(() =>
    loadConfig({
      NODE_ENV: 'production',
      GEMINI_API_KEY: 'server-key',
      CONVERSATION_SIGNING_SECRET: secret,
      GOOGLE_CLOUD_PROJECT: 'project',
      ALLOW_UNAUTHENTICATED_DEV: 'true',
    }),
  );
});

test('quota and safety failures are sanitized', () => {
  assert.equal(mapGeminiError({ status: 429, message: 'quota exceeded' }).code, 'quota_exceeded');
  assert.equal(mapGeminiError({ status: 400, message: 'input blocked by safety' }).code, 'safety_blocked');
});

test('chat endpoint returns response text and signed context without storing history', async () => {
  let received;
  const ai = {
    interactions: {
      create: async (request) => {
        received = request;
        return {
          id: 'gemini-interaction-1',
          output_text: 'Move to higher ground and follow local authorities.',
        };
      },
    },
  };
  const app = createApp({
    config: {
      nodeEnv: 'test',
      apiKey: 'not-used-by-mock',
      model: 'gemini-3.5-flash-lite',
      signingSecret: secret,
      projectId: '',
      port: 0,
      allowUnauthenticatedDev: true,
    },
    ai,
  });
  const server = app.listen(0, '127.0.0.1');
  await new Promise((resolve) => server.once('listening', resolve));
  try {
    const address = server.address();
    const response = await fetch(`http://127.0.0.1:${address.port}/v1/chat`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ message: 'Ano ang gagawin sa baha?', locale: 'fil-PH' }),
    });
    const body = await response.json();
    assert.equal(response.status, 200);
    assert.equal(body.text, 'Move to higher ground and follow local authorities.');
    assert.match(body.interactionId, /\./);
    assert.equal(received.model, 'gemini-3.5-flash-lite');
    assert.match(received.system_instruction, /User locale: fil-PH/);
  } finally {
    await new Promise((resolve, reject) =>
      server.close((error) => (error ? reject(error) : resolve())),
    );
  }
});
