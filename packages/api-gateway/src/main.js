import Fastify from 'fastify';
import { connect } from 'nats';
import { Client } from 'pg';
import crypto from 'crypto';
import dotenv from 'dotenv';

dotenv.config();
const nats = await connect({ servers: process.env.NATS_URL });
const pg = new Client({ connectionString: process.env.DATABASE_URL });
await pg.connect();
const app = Fastify();

app.post('/trades/open', async (req, reply) => {
  const mock = {
    trade_id: crypto.randomUUID(),
    user_addr: '0xabc',
    pnl_usd: 5,
    leverage_x: 3,
    ts_unix: Date.now()
  };
  await nats.publish('trade.closed', JSON.stringify(mock));
  await pg.query(
    'INSERT INTO trades(trade_id, user_addr, pnl_usd, leverage_x, ts_unix) VALUES ($1,$2,$3,$4,$5)',
    [mock.trade_id, mock.user_addr, mock.pnl_usd, mock.leverage_x, mock.ts_unix]
  );
  return { ok: true, id: mock.trade_id };
});

app.listen({ port: 3000 }, () => console.log('API Gateway 3000'));
