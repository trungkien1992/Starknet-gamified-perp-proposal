# AGENTS.md – StreetCred Clash

## Branch & commit
| Rule | Value |
|------|-------|
| Branch | `feat/*`, `fix/*`, `test/*` |
| Commit | Conventional Commits |

## Tooling required in CI
* `pnpm install` → `turbo lint` → `pnpm test` (Jest ≥ 80 % line)
* `flutter test` in /frontend (allow to fail on CI mobile-less runners)

## Security & style
* Parameterised SQL only (`$1…`).
* Never shell-interpolate untrusted env vars.
* No `console.log`; use `pino`.
