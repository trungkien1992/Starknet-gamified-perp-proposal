import Fastify from 'fastify';
import { connect as connectNats } from 'nats';
import { Pool } from 'pg';
import { processTrade } from './lib/pipeline.js';
import dotenv from 'dotenv';
import pino from 'pino';

dotenv.config();
const log = pino();
const app = Fastify();
app.get('/healthz', async () => ({ ok: true }));
await app.listen({ port: 3001 });
log.info('Gamecore 3001');
const nats = await connectNats({ servers: process.env.NATS_URL });
const pg = new Pool({ connectionString: process.env.DATABASE_URL });

const js = nats.jetstream();
const sub = await js.pullSubscribe('trade.closed', { durable: 'gamecore' });
const pull = () => sub.pull({ batch: 1, expires: 1000 });
pull();
for await (const m of sub) {
  try {
    const trade = JSON.parse(m.data);
    await processTrade(trade, pg, nats);
    log.info({ tradeId: trade.trade_id }, 'Ink updated');
    m.ack();
  } catch (err) {
    log.error(err);
  } finally {
    pull();
  }
}

process.on('SIGINT', async () => {
  await nats.drain();
  await pg.end();
  process.exit(0);
});
