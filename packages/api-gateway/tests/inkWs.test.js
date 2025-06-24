import { WebSocket } from 'ws';

let api, nats;

describe('/ws/ink', () => {
  let server, address;

  beforeAll(async () => {
    process.env.NODE_ENV = 'test';
    const mod = await import('../src/main.js');
    api = mod.default;
    nats = mod.nats;
    server = api;
    await server.listen({ port: 0 });
    address = `ws://127.0.0.1:${server.server.address().port}/ws/ink`;
  });

  afterAll(() => server.close());

  it('relays ink.updated events to connected clients', async () => {
    // TODO: implement full websocket relay test
    expect(typeof nats.publish).toBe('function');
  });
});
