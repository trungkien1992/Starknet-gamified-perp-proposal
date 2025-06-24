import Fastify from 'fastify';
import ws from '@fastify/websocket';
import cors from '@fastify/cors';
import { connect } from 'nats';
import { Pool } from 'pg';
import crypto from 'crypto';
import dotenv from 'dotenv';

dotenv.config();
const nats = await connect({ servers: process.env.NATS_URL });
const pg = new Pool({ connectionString: process.env.DATABASE_URL });
const app = Fastify();
app.register(cors, {
  origin: '*', // TODO tighten in prod
  allowedHeaders: ['sec-websocket-protocol'] // future JWT / wallet-sig
});
app.register(ws);

app.get('/healthz', async () => {
  return { ok: true };
});

app.post('/trades/open', async (req, reply) => {
  try {
    const body = req.body;
    const trade = {
      trade_id: crypto.randomUUID(),
      user_addr: body.user,
      pnl_usd: 5,
      leverage_x: body.lev,
      asset: body.asset,
      dir: body.dir,
      ts_unix: Date.now()
    };
    await pg.query(
      'INSERT INTO trades(trade_id, user_addr, pnl_usd, leverage_x, ts_unix) VALUES ($1,$2,$3,$4,$5)',
      [trade.trade_id, trade.user_addr, trade.pnl_usd, trade.leverage_x, trade.ts_unix]
    );
    await nats.publish('trade.closed', JSON.stringify(trade));
    return { ok: true, id: trade.trade_id };
  } catch (err) {
    console.error(err);
    reply.status(500);
    return { ok: false };
  }
});

app.get('/ws/ink', { websocket: true }, (socket) => {
  const sub = nats.subscribe('ink.updated');
  void (async () => {
    try {
      for await (const m of sub) {
        socket.raw.write(m.data);
      }
    } catch (err) {
      app.log.error(err, 'WS relay error');
      socket.close();
    }
  })();
});

app.listen({ port: 3000 }, () => console.log('API Gateway 3000'));
