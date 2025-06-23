import Fastify from 'fastify';
import { connect } from 'nats';
import crypto from 'crypto';

const nats = await connect({ servers: 'nats://localhost:4222' });
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
  return { ok: true, id: mock.trade_id };
});

app.listen({ port: 3000 }, () => console.log('API Gateway 3000'));
