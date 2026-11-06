import assert from 'node:assert/strict';
import test from 'node:test';

import {
  createAlertAggregator,
  fetchPagasaCap,
  normalizeAlerts,
} from '../src/alerts.js';

function alert(id, title, priority, updatedAt = '2026-10-25T09:00:00Z') {
  return {
    id,
    title,
    description: 'Fixture',
    issuedAt: '2026-10-25T08:00:00Z',
    updatedAt,
    visualPriority: priority,
    agency: 'Fixture',
    category: 'earthquake',
  };
}

test('normalization deduplicates revisions and sorts by visual priority', () => {
  const result = normalizeAlerts([
    alert('old', 'Same event', 'Medium'),
    alert('new', 'Same event', 'High', '2026-10-25T10:00:00Z'),
    { ...alert('critical', 'Different event', 'Critical'), category: 'weather' },
  ]);

  assert.equal(result.length, 2);
  assert.equal(result[0].id, 'critical');
  assert.equal(result[1].id, 'new');
});

test('aggregator isolates provider failure and reports source health', async () => {
  const aggregator = createAlertAggregator({
    now: () => new Date('2026-10-25T10:00:00Z'),
    providers: [
      ['ok', 'Working source', async () => [alert('one', 'Event one', 'High')]],
      ['down', 'Unavailable source', async () => { throw new Error('offline'); }],
    ],
  });

  const result = await aggregator.getAlerts();
  assert.equal(result.alerts.length, 1);
  assert.equal(result.sources.find((source) => source.id === 'ok').available, true);
  assert.equal(result.sources.find((source) => source.id === 'down').available, false);
});

test('aggregator serves a recent saved response when every provider fails', async () => {
  let fail = false;
  let clock = new Date('2026-10-25T10:00:00Z');
  const aggregator = createAlertAggregator({
    now: () => clock,
    providers: [
      ['source', 'Fixture source', async () => {
        if (fail) throw new Error('offline');
        return [alert('one', 'Event one', 'High')];
      }],
    ],
  });

  await aggregator.getAlerts();
  fail = true;
  clock = new Date('2026-10-25T10:06:00Z');
  const cached = await aggregator.getAlerts();
  assert.equal(cached.cache.status, 'stale');
  assert.equal(cached.alerts.length, 1);
});

test('PAGASA CAP adapter preserves official provenance and active lifecycle', async () => {
  const atom = `<feed xmlns='http://www.w3.org/2005/Atom'>
      <entry><id>urn:uuid:alert-1</id><title>Yellow Rainfall Warning</title>
      <updated>2026-11-07T02:00:00+08:00</updated>
      <link type='application/cap+xml' href='https://pagasa.test/alert-1.cap'/></entry>
    </feed>`;
  const cap = `<alert xmlns='urn:oasis:names:tc:emergency:cap:1.2'>
      <identifier>alert-1</identifier><sender>PAGASA-DOST</sender>
      <sent>2026-11-07T02:00:00+08:00</sent><status>Actual</status>
      <msgType>Alert</msgType><scope>Public</scope>
      <info><event>Yellow Rainfall Warning</event><urgency>Expected</urgency>
      <severity>Moderate</severity><certainty>Likely</certainty>
      <expires>2026-11-07T08:00:00+08:00</expires>
      <headline>Yellow Rainfall Warning</headline>
      <description>Flooding is possible in low-lying areas.</description>
      <instruction>Monitor local conditions.</instruction>
      <web>https://pagasa.test/bulletin</web>
      <area><areaDesc>Metro Manila</areaDesc></area></info>
    </alert>`;
  const fetchImpl = async (url) => ({
    ok: true,
    status: 200,
    text: async () => url.endsWith('.cap') ? cap : atom,
  });

  const result = await fetchPagasaCap(
    fetchImpl,
    new Date('2026-11-06T20:00:00Z'),
  );
  assert.equal(result.length, 1);
  assert.equal(result[0].agency, 'DOST-PAGASA');
  assert.equal(result[0].verificationStatus, 'official');
  assert.equal(result[0].visualPriority, 'Medium');
  assert.deepEqual(result[0].affectedAreas, ['Metro Manila']);
  assert.equal(result[0].expiresAt, '2026-11-07T00:00:00.000Z');
});
