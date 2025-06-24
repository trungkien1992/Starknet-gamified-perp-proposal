import Fastify from 'fastify';
import ws from '@fastify/websocket';
import cors from '@fastify/cors';
import { connect } from 'nats';
import { EventEmitter } from 'events';
import { Pool } from 'pg';
import crypto from 'crypto';
import dotenv from 'dotenv';

dotenv.config();
let nats;
if (process.env.NODE_ENV === 'test' || !process.env.NATS_URL) {
  const ee = new EventEmitter();
  nats = {
    publish: (subj, data) => ee.emit(subj, data),
    subscribe: (subj) => {
      const iter = (async function* () {
        const q = [];
        const handler = (msg) => q.push({ data: msg });
        ee.on(subj, handler);
        try {
          while (true) {
            if (q.length) {
              yield q.shift();
            } else {
              await new Promise((res) => ee.once(subj, (m) => {
                q.push({ data: m });
                res();
              }));
            }
          }
        } finally {
          ee.off(subj, handler);
        }
      })();
      return { [Symbol.asyncIterator]: () => iter, unsubscribe() {} };
    }
  };
} else {
  nats = await connect({ servers: process.env.NATS_URL });
}
export { nats };
const pg = new Pool({ connectionString: process.env.DATABASE_URL });
const app = Fastify();
app.register(cors, {
  origin: '*', // TODO tighten in prod
  allowedHeaders: ['sec-websocket-protocol'] // future JWT / wallet-sig
});
app.register(ws);
app.get('/healthz', async (_, reply) => {
  reply.code(200);
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
    app.log.error(err);
    reply.status(500);
    return { ok: false };
  }
});

app.get('/ws/ink', { websocket: true }, (socket) => {
  const sub = nats.subscribe('ink.updated');
  const iter = sub[Symbol.asyncIterator]();

  const cleanup = () => {
    sub.unsubscribe();
    if (typeof iter.return === 'function') iter.return();
  };

  socket.on('close', cleanup);

  void (async () => {
    try {
      for await (const m of iter) {
        if (!socket.raw.write(m.data)) {
          await new Promise((res) => socket.raw.once('drain', res));
        }
      }
    } catch (err) {
      app.log.error(err, 'WS relay error');
    } finally {
      cleanup();
    }
  })();
});

app.get('/ws/rewards', { websocket: true }, (socket) => {
  const sub = nats.subscribe('reward.dropped');
  void (async () => {
    try {
      for await (const m of sub) {
        if (!socket.raw.write(m.data)) {
          await new Promise(res => socket.raw.once('drain', res));
        }
      }
    } catch (err) {
      app.log.error(err, 'WS reward relay error');
      socket.close();
    }
  })();
  socket.on('close', () => sub.unsubscribe());
});

if (process.env.NODE_ENV !== 'test') {
  app.listen({ port: 3000 }, () => app.log.info('API Gateway 3000'));
}

export default app;

process.on('SIGINT', async () => {
  if (nats.drain) await nats.drain();
  await pg.end();
  process.exit(0);
});
