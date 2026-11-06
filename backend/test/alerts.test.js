import assert from 'node:assert/strict';
import test from 'node:test';

import { createAlertAggregator, normalizeAlerts } from '../src/alerts.js';

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
