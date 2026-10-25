import crypto from 'node:crypto';

const encode = (value) => Buffer.from(value).toString('base64url');

export function signConversationToken({ interactionId, uid, secret, now = Date.now() }) {
  const payload = encode(
    JSON.stringify({
      interactionId,
      uid,
      expiresAt: now + 24 * 60 * 60 * 1000,
    }),
  );
  const signature = crypto.createHmac('sha256', secret).update(payload).digest('base64url');
  return `${payload}.${signature}`;
}

export function verifyConversationToken({ token, uid, secret, now = Date.now() }) {
  if (typeof token !== 'string' || token.length > 1024) throw new Error('invalid_context');
  const [payload, signature, extra] = token.split('.');
  if (!payload || !signature || extra) throw new Error('invalid_context');
  const expected = crypto.createHmac('sha256', secret).update(payload).digest();
  const actual = Buffer.from(signature, 'base64url');
  if (actual.length !== expected.length || !crypto.timingSafeEqual(actual, expected)) {
    throw new Error('invalid_context');
  }
  const decoded = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8'));
  if (decoded.uid !== uid || decoded.expiresAt < now || !decoded.interactionId) {
    throw new Error('invalid_context');
  }
  return decoded.interactionId;
}
