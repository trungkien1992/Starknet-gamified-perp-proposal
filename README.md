

# StreetCred Clash Scaffold

This repository contains a minimal Turborepo monorepo setup for the StreetCred Clash project, including Node.js backend services and a Flutter frontend.

---

## Prerequisites

Before starting development, ensure you have the following installed and configured:

- **Node.js** version **≥ 20.0.0**  
- **pnpm** package manager (https://pnpm.io/)  
- **Docker** and **Docker Compose** (https://docs.docker.com/compose/)  
- **PostgreSQL CLI (`psql`)** for running database migrations  
- (Optional) Flutter SDK for mobile or web development (https://flutter.dev/docs/get-started/install)

Make sure Docker is running before starting services.

---

## Development Setup

### 1. Install dependencies

Run this command at the root of the repo to install all workspace dependencies:

```bash
pnpm install
```

### 2. Start infrastructure services

Launch PostgreSQL and NATS messaging server via Docker Compose:

```bash
docker compose -f docker/docker-compose.yml up -d
```

To stop these services later:

```bash
docker compose -f docker/docker-compose.yml down
```

### 3. Configure environment variables

Copy the example environment file into each backend service directory so that `dotenv` can load configuration:

```bash
cp .env.example packages/api-gateway/.env
cp .env.example packages/gamecore/.env
```

If you add or modify environment variables, be sure to update these `.env` files accordingly.

### 4. Run database migrations

Apply the latest database schema changes (requires `psql` CLI):

```bash
pnpm db:migrate
```

This runs migrations for all relevant services. To re-run or rollback, consult your migration tooling documentation.

---

## Running the Services

### Run all services and frontend together

Start the API Gateway, GameCore backend, and Flutter web app concurrently:

```bash
pnpm dev
```

### Run individual services

You can also run services separately in different terminals:

```bash
# Start API Gateway service
pnpm --filter api-gateway dev

# Start GameCore service
pnpm --filter gamecore dev

# Start Flutter web frontend
pnpm --filter frontend dev
```

---

## Additional Tips

- **Logging & Monitoring:** Check logs in terminal windows for each service. Use Docker logs for Postgres and NATS.  
- **Testing:** Run unit and integration tests with `pnpm test` (Node only). Use `pnpm test:all` to include Flutter tests.
- **UI tests require the Flutter SDK.** Run `pnpm --filter frontend flutter:test` locally before committing UI changes.
- **Code Formatting:** Use `pnpm lint` and `pnpm format` to maintain code style consistency.
- **CI/CD:** Ensure your CI pipeline runs `pnpm install`, `pnpm db:migrate`, and tests before deployment.

---

## Troubleshooting

- If you encounter connection issues, verify Docker containers are running (`docker ps`).  
- Ensure your `.env` files contain correct database and NATS connection strings.  
- For Flutter build issues, confirm Flutter SDK is installed and environment variables are set.

---

This README aims to provide a smooth onboarding experience for new developers and maintainers. Please update it as the project evolves.

