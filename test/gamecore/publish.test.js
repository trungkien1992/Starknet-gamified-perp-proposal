import { processTrade } from '../../packages/gamecore/src/lib/pipeline.js';
import { jest } from '@jest/globals';

test('reward emitted when total reaches threshold', async () => {
  const pg = { query: jest.fn() };
  const nats = { publish: jest.fn() };
  pg.query.mockResolvedValueOnce({});
  pg.query.mockResolvedValueOnce({ rows: [{ total: 60 }] });

  await processTrade({ trade_id: '1', user_addr: '0x1', pnl_usd: 12, leverage_x: 5 }, pg, nats);

  expect(nats.publish).toHaveBeenCalledWith('reward.dropped', expect.any(String));
});

test('no reward when below threshold', async () => {
  const pg = { query: jest.fn() };
  const nats = { publish: jest.fn() };
  pg.query.mockResolvedValueOnce({});
  pg.query.mockResolvedValueOnce({ rows: [{ total: 30 }] });

  await processTrade({ trade_id: '2', user_addr: '0x1', pnl_usd: 2, leverage_x: 2 }, pg, nats);

  expect(nats.publish).not.toHaveBeenCalledWith('reward.dropped', expect.any(String));
});
