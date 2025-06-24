import { connect as connectNats } from 'nats';
import { Pool } from 'pg';
import dotenv from 'dotenv';

dotenv.config();
const nats = await connectNats({ servers: process.env.NATS_URL });
const pg = new Pool({ connectionString: process.env.DATABASE_URL });

const sub = nats.subscribe('trade.closed');
for await (const m of sub) {
  const trade = JSON.parse(m.data);
  const ink = Math.floor(trade.pnl_usd * trade.leverage_x);
  await pg.query(
    'INSERT INTO ink_ledger(trade_id, ink_delta) VALUES ($1, $2)',
    [trade.trade_id, ink]
  );
  await nats.publish(
    'ink.updated',
    JSON.stringify({ trade_id: trade.trade_id, ink_delta: ink })
  );
  console.log('Ink updated', trade.trade_id, ink);
}
