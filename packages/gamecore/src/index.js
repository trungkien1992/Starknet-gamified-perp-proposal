import { connect as connectNats } from 'nats';
import { Client } from 'pg';

const nats = await connectNats({ servers: 'nats://localhost:4222' });
const pg = new Client({ connectionString: 'postgres://postgres:secr3t@localhost:5432/postgres' });
await pg.connect();

const sub = nats.subscribe('trade.closed');
for await (const m of sub) {
  const trade = JSON.parse(m.data);
  await pg.query('INSERT INTO ink_ledger(trade_id, ink_delta) VALUES ($1, $2)', [trade.trade_id, trade.pnl_usd]);
  console.log('Ink updated', trade.trade_id, trade.pnl_usd);
}
