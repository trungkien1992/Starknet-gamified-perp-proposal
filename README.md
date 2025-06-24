# StreetCred Scaffold

This repository contains a minimal Turborepo monorepo setup.

## Development

Install dependencies using pnpm:

```bash
pnpm install
```

Start Postgres and NATS via Docker Compose:

```bash
docker compose -f docker/docker-compose.yml up -d
```

Copy the environment file into each service directory so `dotenv` can load it:

```bash
cp .env.example packages/api-gateway/.env
cp .env.example packages/gamecore/.env
```

Run the database migration script (requires `psql`):

```bash
pnpm db:migrate
```

### Running the services

To launch the API gateway and game core together with the Flutter web app, run:

```bash
pnpm dev
```

You can also run them individually:

```bash
# Node services
pnpm --filter api-gateway dev
pnpm --filter gamecore dev

# Flutter app (web)
pnpm --filter frontend dev
```
