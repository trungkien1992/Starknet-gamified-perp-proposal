export function calcInk(pnl, lev) {
  const ink = Math.floor(pnl * lev);
  return ink > 0 ? ink : 0;
}
