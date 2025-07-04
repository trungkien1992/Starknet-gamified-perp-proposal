# Docker Development Environment

This Docker setup provides a complete development environment for the Starknet Gamified Perp Proposal project, solving the macOS ARM compatibility issues with the Starknet Rust SDK.

## 🚀 Quick Start

### Prerequisites
- Docker Desktop installed and running
- Git

### Start the Development Environment

1. **Clone and navigate to the project:**
   ```bash
   cd /path/to/Starknet-gamified-perp-proposal-1
   ```

2. **Start all services:**
   ```bash
   ./scripts/dev.sh start
   ```

3. **Access the development environment:**
   ```bash
   ./scripts/dev.sh shell
   ```

## 📋 Available Commands

Use the development script for common operations:

```bash
./scripts/dev.sh [COMMAND]
```

| Command | Description |
|---------|-------------|
| `start` | Start all services |
| `stop` | Stop all services |
| `restart` | Restart all services |
| `build` | Build all services |
| `logs` | Show logs for all services |
| `core-logs` | Show logs for core-service only |
| `shell` | Open shell in core-service container |
| `test` | Run tests in core-service |
| `clean` | Stop and remove all containers, networks, and volumes |
| `status` | Show status of all services |
| `help` | Show help message |

## 🏗️ Services Overview

The Docker environment includes:

| Service | Port | Description |
|---------|------|-------------|
| **core-service** | 50051 | Rust gRPC service with Starknet integration |
| **api-gateway** | 8000 | Python API gateway |
| **persistence-service** | 8001 | Python persistence service |
| **postgres** | 5432 | PostgreSQL database |
| **kafka** | 9092 | Apache Kafka for event streaming |
| **zookeeper** | 2181 | Zookeeper for Kafka |
| **katana** | 5050 | Starknet devnet (Katana) |
| **redis** | 6379 | Redis cache |

## 🔧 Development Workflow

### 1. Working with the Core Service

```bash
# Open a shell in the core-service container
./scripts/dev.sh shell

# Inside the container, you can:
cargo build          # Build the project
cargo test           # Run tests
cargo run            # Run the service
cargo check          # Check for compilation errors
```

### 2. Viewing Logs

```bash
# View all service logs
./scripts/dev.sh logs

# View only core-service logs
./scripts/dev.sh core-logs
```

### 3. Running Tests

```bash
# Run tests in the core-service
./scripts/dev.sh test
```

### 4. Rebuilding Services

```bash
# Rebuild all services
./scripts/dev.sh build

# Or rebuild just the core-service
docker-compose build core-service
```

## 🐛 Troubleshooting

### Common Issues

1. **Port conflicts:**
   ```bash
   # Check what's using a port
   lsof -i :50051
   
   # Stop conflicting services or change ports in docker-compose.yml
   ```

2. **Docker out of space:**
   ```bash
   # Clean up Docker resources
   ./scripts/dev.sh clean
   ```

3. **Build cache issues:**
   ```bash
   # Rebuild without cache
   docker-compose build --no-cache
   ```

4. **Permission issues:**
   ```bash
   # Make sure the dev script is executable
   chmod +x scripts/dev.sh
   ```

### Reset Everything

If you need to start fresh:

```bash
# Stop and remove everything
./scripts/dev.sh clean

# Start again
./scripts/dev.sh start
```

## 🔄 Development Tips

### 1. Hot Reloading
The core-service code is mounted as a volume, so changes are reflected immediately. However, you need to restart the service:

```bash
# Inside the container
cargo run
```

### 2. Cargo Cache
Cargo dependencies are cached in a Docker volume, so subsequent builds are faster.

### 3. Database Migrations
Database migrations are automatically applied when the PostgreSQL container starts.

### 4. Environment Variables
Environment variables are configured in `docker-compose.yml`. You can modify them there or create a `.env` file.

## 🌐 Accessing Services

Once started, you can access:

- **Core Service gRPC:** `localhost:50051`
- **API Gateway:** `http://localhost:8000`
- **Persistence Service:** `http://localhost:8001`
- **PostgreSQL:** `localhost:5432`
- **Kafka:** `localhost:9092`
- **Katana (Starknet):** `http://localhost:5050`
- **Redis:** `localhost:6379`

## 📝 Configuration

### Environment Variables

Key environment variables in `docker-compose.yml`:

- `RUST_LOG`: Logging level for Rust services
- `KAFKA_BROKERS`: Kafka connection string
- `STARKNET_RPC_URL`: Starknet RPC endpoint
- `DATABASE_URL`: PostgreSQL connection string

### Customizing the Setup

1. **Add new services:** Edit `docker-compose.yml`
2. **Modify build process:** Edit `services/core-service/Dockerfile`
3. **Add development tools:** Modify the Dockerfile to install additional packages

## 🚀 Production Considerations

This setup is for development only. For production:

1. Use production-grade images
2. Configure proper security settings
3. Set up monitoring and logging
4. Use external databases and message queues
5. Configure proper networking and firewalls

## 📚 Additional Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Rust Docker Official Image](https://hub.docker.com/_/rust)
- [Starknet Documentation](https://docs.starknet.io/)
- [Katana Devnet](https://book.dojoengine.org/toolchain/katana/overview.html)

## 🤝 Contributing

When contributing to this project:

1. Use the Docker environment for development
2. Test your changes in the containerized environment
3. Update this documentation if you modify the Docker setup
4. Ensure all services start correctly with `./scripts/dev.sh start` 