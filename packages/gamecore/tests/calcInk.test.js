import { calcInk } from '../src/lib/calcInk.js';

test('ink = floor(pnl * leverage)', () => {
  expect(calcInk(12.3, 3)).toBe(36);
  expect(calcInk(-4.9, 5)).toBe(0);
});
