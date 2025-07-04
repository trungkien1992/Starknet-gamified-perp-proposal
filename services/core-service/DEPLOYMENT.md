# 🚀 Core Service Deployment Guide

## 📋 Overview

This guide covers the deployment and operation of the Starknet Core Service, which executes live trades on Starknet via Katana devnet.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   gRPC Client   │───▶│  Core Service   │───▶│   Katana RPC    │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │   Kafka Topic   │
                       │  trade-events   │
                       └─────────────────┘
```

## 🔧 Prerequisites

### Required Services
- **Katana Devnet**: Local Starknet development environment
- **Kafka**: Message broker for event publishing
- **Docker**: Container runtime (for production deployment)

### Required Tools
- **Rust 1.82+**: For local development
- **Docker & Docker Compose**: For containerized deployment
- **Git**: Version control

## 🚀 Quick Start

### 1. Environment Setup

Create a `.env` file in the project root:

```bash
# Core Service Configuration
GRPC_PORT=50051
RUST_LOG=info

# Kafka Configuration
KAFKA_BROKERS=localhost:9092
KAFKA_TOPIC=trade-events

# Starknet Configuration
STARKNET_RPC_URL=http://localhost:5050
STARKNET_CHAIN_ID=0x4b4154414e41
STARKNET_ACCOUNT_ADDRESS=0x041a78e741e5af2fec34b695279bc44b2e1c3c09ad98ccd2412343e4f0eaa012
STARKNET_PRIVATE_KEY=0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
SCDRIP_CONTRACT_ADDRESS=0x041a78e741e5af2fec34b695279bc44b2e1c3c09ad98ccd2412343e4f0eaa012
MINT_FUNCTION_SELECTOR=0x12345678

# Security Settings
MAX_FEE_PER_GAS=1000000000000000
TRANSACTION_TIMEOUT_SECONDS=300
```

### 2. Start Dependencies

```bash
# Start Katana devnet
docker-compose up katana -d

# Start Kafka (if not already running)
docker-compose up kafka zookeeper -d

# Wait for services to be ready
sleep 10
```

### 3. Deploy Core Service

#### Option A: Docker Deployment (Recommended)
```bash
# Build and start the service
docker-compose up core-service -d

# Check logs
docker-compose logs -f core-service
```

#### Option B: Local Development
```bash
cd services/core-service

# Build the service
cargo build --release

# Run the service
cargo run --release
```

### 4. Verify Deployment

```bash
# Check service health
curl -X POST http://localhost:50051/health

# Check service logs
docker-compose logs core-service
```

## 🔒 Security Configuration

### Environment Variables

**Critical Security Variables:**
- `STARKNET_PRIVATE_KEY`: Private key for transaction signing
- `STARKNET_ACCOUNT_ADDRESS`: Account address for transactions
- `SCDRIP_CONTRACT_ADDRESS`: Contract address for trade execution

### Security Best Practices

1. **Never commit private keys to version control**
2. **Use environment variables for all sensitive data**
3. **Rotate private keys regularly**
4. **Use separate accounts for development and production**
5. **Monitor transaction logs for suspicious activity**

### Production Security Checklist

- [ ] Private keys stored in secure key management system
- [ ] Environment variables properly configured
- [ ] Network access restricted to necessary ports
- [ ] Logging configured for security monitoring
- [ ] Health checks implemented and monitored
- [ ] Backup and recovery procedures documented

## 📊 Monitoring & Health Checks

### Health Endpoint

The service provides a health check endpoint:

```bash
# Get health status
curl -X POST http://localhost:50051/health
```

**Response Format:**
```json
{
  "status": "healthy",
  "timestamp": "2024-12-19T10:30:00Z",
  "uptime_seconds": 3600,
  "starknet_connected": true,
  "kafka_connected": true,
  "last_transaction_hash": "0x1234...",
  "error_count": 0,
  "success_count": 10
}
```

### Monitoring Metrics

**Key Metrics to Monitor:**
- Service uptime
- Transaction success rate
- Starknet connectivity
- Kafka connectivity
- Response times
- Error rates

### Logging

**Log Levels:**
- `ERROR`: Critical errors requiring immediate attention
- `WARN`: Warning conditions that may need investigation
- `INFO`: General operational information
- `DEBUG`: Detailed debugging information

**Important Log Events:**
- Service startup/shutdown
- Transaction execution (success/failure)
- Health check results
- Configuration validation errors

## 🧪 Testing

### Run Integration Tests

```bash
cd services/core-service

# Run all tests
cargo test

# Run integration tests only
cargo test --test integration_tests

# Run with verbose output
cargo test -- --nocapture
```

### Test Configuration

**Test Environment Variables:**
```bash
# Test-specific configuration
GRPC_PORT=50052
KAFKA_TOPIC=test-trade-events
STARKNET_RPC_URL=http://localhost:5050
```

### Manual Testing

```bash
# Test gRPC endpoint
grpcurl -plaintext -d '{"user_id": "test_user"}' \
  localhost:50051 core_service.CoreService/ExecuteTrade

# Test health endpoint
grpcurl -plaintext localhost:50051 core_service.CoreService/GetHealth
```

## 🔄 Operations

### Service Management

**Start Service:**
```bash
docker-compose up core-service -d
```

**Stop Service:**
```bash
docker-compose stop core-service
```

**Restart Service:**
```bash
docker-compose restart core-service
```

**View Logs:**
```bash
docker-compose logs -f core-service
```

### Configuration Updates

**Update Environment Variables:**
1. Modify `.env` file or environment variables
2. Restart the service: `docker-compose restart core-service`
3. Verify configuration: Check logs for validation messages

**Update Service Code:**
1. Pull latest code: `git pull`
2. Rebuild image: `docker-compose build core-service`
3. Restart service: `docker-compose up core-service -d`

### Troubleshooting

**Common Issues:**

1. **Service won't start**
   - Check environment variables are set correctly
   - Verify dependencies (Katana, Kafka) are running
   - Check logs for configuration errors

2. **Transaction failures**
   - Verify Starknet account has sufficient balance
   - Check contract address is correct
   - Verify Katana devnet is running

3. **Kafka connection issues**
   - Verify Kafka is running and accessible
   - Check broker configuration
   - Verify topic exists

4. **Health check failures**
   - Check Starknet RPC connectivity
   - Verify all required services are running
   - Check service logs for errors

**Debug Commands:**
```bash
# Check service status
docker-compose ps

# Check service logs
docker-compose logs core-service

# Check network connectivity
docker-compose exec core-service ping katana

# Check environment variables
docker-compose exec core-service env | grep STARKNET
```

## 📈 Scaling & Performance

### Performance Tuning

**Configuration Parameters:**
- `TRANSACTION_TIMEOUT_SECONDS`: Transaction timeout (default: 300s)
- `MAX_FEE_PER_GAS`: Maximum gas fee (default: 0.001 ETH)
- `KAFKA_BROKERS`: Kafka broker configuration

**Resource Limits:**
```yaml
# docker-compose.yml
core-service:
  deploy:
    resources:
      limits:
        memory: 1G
        cpus: '0.5'
      reservations:
        memory: 512M
        cpus: '0.25'
```

### Horizontal Scaling

**Multiple Instances:**
```bash
# Scale to multiple instances
docker-compose up --scale core-service=3 -d
```

**Load Balancing:**
- Use external load balancer (nginx, haproxy)
- Configure gRPC load balancing
- Monitor instance health

## 🔄 Backup & Recovery

### Backup Procedures

**Configuration Backup:**
```bash
# Backup environment configuration
cp .env .env.backup.$(date +%Y%m%d)
```

**Service State Backup:**
- Transaction logs
- Health check history
- Error logs

### Recovery Procedures

**Service Recovery:**
1. Stop service: `docker-compose stop core-service`
2. Restore configuration if needed
3. Start service: `docker-compose up core-service -d`
4. Verify health: Check health endpoint

**Data Recovery:**
- Replay failed transactions from logs
- Verify transaction status on Starknet
- Update service state if needed

## 📞 Support

### Contact Information

- **Technical Issues**: Create GitHub issue
- **Security Issues**: Report via security@example.com
- **Documentation**: Update this guide

### Useful Resources

- [Starknet Documentation](https://docs.starknet.io/)
- [Katana Devnet Guide](https://book.dojoengine.org/)
- [Docker Documentation](https://docs.docker.com/)
- [Kafka Documentation](https://kafka.apache.org/documentation/)

---

**Last Updated**: December 2024  
**Version**: 1.0.0 