# Starknet Gamified Perp

A gamified perpetual trading platform built on Starknet with Cairo smart contracts and Flutter frontend.

## 🏗️ Architecture

- **Smart Contracts**: Cairo 2.8.0 contracts using OpenZeppelin v0.9.0
- **Local Development**: Katana v1.5.4 (Docker-based)
- **Frontend**: Flutter app with Starknet integration
- **Backend Services**: Rust core service, Python API gateway, and persistence service

## 🚀 Quick Start

### Prerequisites

- **macOS Apple Silicon** (M1/M2/M3) - See [Platform Notes](#platform-notes) for other platforms
- Docker Desktop with 4+ CPUs and 4GB+ RAM allocated
- Scarb 2.8.0
- Flutter 3.x
- Node.js 18+ and pnpm

### 1. Start Local Starknet (Katana)

```bash
# Start Katana in Docker
./run_katana_docker.sh

# Verify it's running
curl -X POST http://localhost:5050 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"starknet_chainId","params":[],"id":1}'
```

### 2. Build and Test Contracts

```bash
cd contracts

# Build contracts
scarb build

# Run tests
scarb test

# Deploy to local Katana
scarb deploy
```

### 3. Start Frontend

```bash
cd frontend

# Install dependencies
flutter pub get

# Run on iOS simulator
flutter run -d ios

# Or run on web
flutter run -d chrome
```

### 4. Start Backend Services

```bash
# Start all services
docker-compose -f docker/docker-compose.yml up -d
```

## 📚 Development Workflow

### Contract Development

1. **Write contracts** in `contracts/src/`
2. **Test locally** with `scarb test`
3. **Deploy to Katana** with `scarb deploy`
4. **Update frontend** to use new contract addresses

### Frontend Development

1. **Update contract bindings** when contracts change
2. **Test wallet integration** with Katana accounts
3. **Run integration tests** with `flutter test`
4. **Navigation**: Uses GoRouter for all screen transitions. Main routes: `/`, `/arena`, `/drip`, `/profile`, `/streaks`, `/reward`. Login-based redirect ensures protected routes require wallet connection.
5. **XP Flow**: XPNotifier manages XP state, incremented on moves/trades, with visual feedback in the UI.
6. **UI Links**: Trade Arena header includes quick links to `/drip` and `/streaks`.

### Testing Strategy

- **Unit Tests**: `scarb test` for contracts, `flutter test` for frontend
- **Widget Tests**: Includes navigation and login redirect test for GoRouter and XP flow
- **Integration Tests**: End-to-end testing with Katana
- **Gas Testing**: Measure gas consumption for optimizations

## 🔧 Configuration

### Version Matrix

| Component | Version | Notes |
|-----------|---------|-------|
| Cairo | 2.8.0 | Latest stable |
| Scarb | 2.8.0 | Matches Cairo |
| Katana | 1.5.4 | Docker image |
| OpenZeppelin | v0.9.0 | Cairo contracts |
| Flutter | 3.x | Latest stable |

### Environment Variables

Create `.env` files in each service directory:

```bash
# contracts/.env
KATANA_RPC_URL=http://localhost:5050
DEPLOYER_PRIVATE_KEY=0x1234567890abcdef...

# frontend/.env
STARKNET_RPC_URL=http://localhost:5050
CONTRACT_ADDRESS=0x...
```

## 🐛 Troubleshooting

### Common Issues

1. **Katana not starting**: Check Docker Desktop resources and restart
2. **Contract build failures**: Verify Cairo/Scarb versions match
3. **Frontend connection errors**: Ensure Katana RPC is accessible
4. **Gas estimation failures**: Check account balance in Katana

### Debug Commands

```bash
# Check Katana status
docker logs katana

# Verify RPC health
curl -X POST http://localhost:5050 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"starknet_chainId","params":[],"id":1}'

# Check contract deployment
scarb deploy --show-addresses
```

## 📋 Platform Notes

### macOS Apple Silicon (M1/M2/M3)

- ✅ **Fully Supported**: All components work natively
- 🐳 **Docker**: ARM64 images available for all services
- ⚡ **Performance**: Native ARM64 binaries for best performance

### Linux (x86_64)

- ✅ **Supported**: All components work
- 🔧 **Setup**: Use x86_64 Docker images
- 📦 **Installation**: Standard package managers work

### Windows

- ⚠️ **Limited Support**: WSL2 recommended
- 🐳 **Docker**: Use WSL2 backend
- 🔧 **Setup**: Follow Linux instructions in WSL2

## 🔄 CI/CD Integration

### GitHub Actions

The project includes automated testing:

```yaml
# .github/workflows/test.yml
name: Test
on: [push, pull_request]
jobs:
  test-contracts:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: |
          curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh
          scarb test
```

### Local CI

Run the full test suite locally:

```bash
# Run all tests
./scripts/test_local.sh
```

## 📖 Additional Documentation

- [Contract Development Guide](docs/CONTRACT_DEVELOPMENT.md)
- [Frontend Integration Guide](docs/FRONTEND_INTEGRATION.md)
- [Testing Strategy](docs/TESTING_STRATEGY.md)
- [Deployment Guide](docs/DEPLOYMENT.md)
- [Known Issues](KNOWN_ISSUES.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Follow the development workflow
4. Add tests for new functionality
5. Submit a pull request

## 📄 License

MIT

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/your-repo/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-repo/discussions)
- **Documentation**: [Project Wiki](https://github.com/your-repo/wiki)
