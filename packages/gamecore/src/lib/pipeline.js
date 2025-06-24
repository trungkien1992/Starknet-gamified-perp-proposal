import { calcInk } from './calcInk.js';

export async function processTrade(trade, pg, nats) {
  const ink = calcInk(trade.pnl_usd, trade.leverage_x);
  if (ink === 0) {
    return false;
  }
  await pg.query('INSERT INTO ink_ledger(trade_id, ink_delta) VALUES ($1, $2)', [trade.trade_id, ink]);
  await nats.publish('ink.updated', JSON.stringify({ user_addr: trade.user_addr, ink_delta: ink }));
  const { rows } = await pg.query('SELECT COALESCE(SUM(ink_delta),0) AS total FROM ink_ledger il JOIN trades t ON il.trade_id=t.trade_id WHERE t.user_addr=$1', [trade.user_addr]);
  if (rows[0].total >= 50) {
    await nats.publish('reward.dropped', JSON.stringify({ user_addr: trade.user_addr, kind: 'hoodie' }));
  }
  return true;
}
