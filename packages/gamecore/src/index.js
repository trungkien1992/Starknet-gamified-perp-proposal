import Fastify from 'fastify';
import { connect as connectNats } from 'nats';
import { Pool } from 'pg';
import dotenv from 'dotenv';

dotenv.config();
const nats = await connectNats({ servers: process.env.NATS_URL });
const pg = new Pool({ connectionString: process.env.DATABASE_URL });
const app = Fastify();
app.get('/healthz', async () => ({ ok: true }));
app.listen({ port: 3001 }, () => console.log('Gamecore 3001'));

const sub = nats.subscribe('trade.closed');
for await (const m of sub) {
  try {
    const trade = JSON.parse(m.data);
    const ink = Math.floor(trade.pnl_usd * trade.leverage_x);
    if (ink < 0) continue; // skip negative payouts
    await pg.query(
      'INSERT INTO ink_ledger(trade_id, ink_delta) VALUES ($1, $2)',
      [trade.trade_id, ink]
    );
    await nats.publish(
      'ink.updated',
      JSON.stringify({ user_addr: trade.user_addr, ink_delta: ink })
    );
    const { rows } = await pg.query(
      'SELECT COALESCE(SUM(ink_delta),0) AS total FROM ink_ledger il ' +
        'JOIN trades t ON il.trade_id=t.trade_id WHERE t.user_addr=$1',
      [trade.user_addr]
    );
    if (rows[0].total >= 50) {
      await nats.publish(
        'reward.dropped',
        JSON.stringify({ user_addr: trade.user_addr, kind: 'hoodie' })
      );
    }
    console.log('Ink updated', trade.trade_id, ink);
  } catch (err) {
    console.error(err);
  }
}

process.on('SIGINT', async () => {
  await nats.drain();
  await pg.end();
  process.exit(0);
});
