# Deployment Guide

## Overview

This guide covers deploying the StreetCred Clash backend services in development and production environments.

## Prerequisites

- **Docker & Docker Compose** (v20.10+)
- **Rust** (v1.70+) for local development
- **PostgreSQL** (v14+) for data persistence
- **Kafka** (v3.0+) for event streaming
- **Starknet Node** (Katana for development)

## Quick Start (Development)

### 1. Clone and Setup

```bash
git clone https://github.com/streetcred/clash.git
cd clash
```

### 2. Environment Configuration

Create `.env` file:

```bash
# Copy example environment
cp .env.example .env

# Edit with your values
nano .env
```

Required environment variables:

```bash
# Starknet Configuration
STARKNET_RPC_URL=http://localhost:5050
STARKNET_PRIVATE_KEY=your_private_key_here

# Database Configuration
DATABASE_URL=postgres://user:password@localhost:5432/streetcred_clash
POSTGRES_USER=streetcred
POSTGRES_PASSWORD=secure_password
POSTGRES_DB=streetcred_clash

# Kafka Configuration
KAFKA_BOOTSTRAP_SERVERS=localhost:9092
KAFKA_TOPIC_PLAYER_MOVES=player_moves
KAFKA_TOPIC_TILE_EVENTS=tile_events

# Service Configuration
LOG_LEVEL=info
GRPC_PORT=50051
API_GATEWAY_PORT=8000

# Security
JWT_SECRET=your_jwt_secret_here
CORS_ORIGINS=http://localhost:3000,http://localhost:8080
```

### 3. Start Dependencies

```bash
# Start all required services
docker-compose up -d postgres kafka starknet

# Verify services are running
docker-compose ps
```

### 4. Database Setup

```bash
# Run database migrations
docker-compose exec postgres psql -U streetcred -d streetcred_clash -f /docker-entrypoint-initdb.d/V1__Create_initial_tables.sql

# Or use the migration script
./scripts/migrations/run_migrations.sh
```

### 5. Build and Start Services

```bash
# Build all services
docker-compose build

# Start core service
docker-compose up -d core-service

# Start API gateway
docker-compose up -d api-gateway

# View logs
docker-compose logs -f core-service
```

### 6. Verify Deployment

```bash
# Health check
curl http://localhost:50051/health

# Test gRPC endpoint
grpcurl -plaintext -d '{"user_id": "test_player", "direction": "up"}' \
  localhost:50051 streetcred.core.v1.CoreService/MovePlayer
```

## Production Deployment

### 1. Infrastructure Requirements

#### Minimum Requirements
- **CPU**: 4 cores per service
- **RAM**: 8GB per service
- **Storage**: 100GB SSD
- **Network**: 100 Mbps

#### Recommended Requirements
- **CPU**: 8 cores per service
- **RAM**: 16GB per service
- **Storage**: 500GB NVMe SSD
- **Network**: 1 Gbps

### 2. Production Environment Setup

#### Using Docker Swarm

```bash
# Initialize swarm
docker swarm init

# Create overlay network
docker network create --driver overlay streetcred-network

# Deploy stack
docker stack deploy -c docker-compose.prod.yml streetcred
```

#### Using Kubernetes

```bash
# Apply namespace
kubectl apply -f k8s/namespace.yaml

# Apply secrets
kubectl apply -f k8s/secrets.yaml

# Apply configmaps
kubectl apply -f k8s/configmaps.yaml

# Deploy services
kubectl apply -f k8s/
```

### 3. Production Configuration

#### Environment Variables (Production)

```bash
# Production .env
NODE_ENV=production
LOG_LEVEL=warn

# Database (use managed service)
DATABASE_URL=postgres://user:pass@prod-db.cluster.amazonaws.com:5432/streetcred_clash

# Kafka (use managed service)
KAFKA_BOOTSTRAP_SERVERS=kafka.prod.cluster:9092

# Starknet (use mainnet)
STARKNET_RPC_URL=https://alpha-mainnet.starknet.io
STARKNET_PRIVATE_KEY=${STARKNET_PRIVATE_KEY}

# Security
JWT_SECRET=${JWT_SECRET}
CORS_ORIGINS=https://app.streetcredclash.com

# Monitoring
PROMETHEUS_ENDPOINT=http://prometheus:9090
JAEGER_ENDPOINT=http://jaeger:14268
```

#### Docker Compose (Production)

```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  core-service:
    image: streetcred/clash-core:latest
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '2'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 2G
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
    environment:
      - NODE_ENV=production
      - LOG_LEVEL=warn
    networks:
      - streetcred-network
    secrets:
      - database_url
      - starknet_private_key
      - jwt_secret

  api-gateway:
    image: streetcred/clash-api:latest
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: '1'
          memory: 2G
    ports:
      - "8000:8000"
    networks:
      - streetcred-network
    depends_on:
      - core-service

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    networks:
      - streetcred-network

secrets:
  database_url:
    external: true
  starknet_private_key:
    external: true
  jwt_secret:
    external: true

networks:
  streetcred-network:
    external: true
```

### 4. Database Setup (Production)

#### PostgreSQL Configuration

```sql
-- Create production database
CREATE DATABASE streetcred_clash_prod;

-- Create user with limited permissions
CREATE USER streetcred_app WITH PASSWORD 'secure_password';
GRANT CONNECT ON DATABASE streetcred_clash_prod TO streetcred_app;
GRANT USAGE ON SCHEMA public TO streetcred_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO streetcred_app;

-- Run migrations
\c streetcred_clash_prod
\i /path/to/migrations/V1__Create_initial_tables.sql
```

#### Backup Strategy

```bash
# Automated backup script
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
pg_dump -h $DB_HOST -U $DB_USER -d streetcred_clash_prod > backup_$DATE.sql
aws s3 cp backup_$DATE.sql s3://streetcred-backups/
```

### 5. Monitoring Setup

#### Prometheus Configuration

```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'core-service'
    static_configs:
      - targets: ['core-service:50051']
    metrics_path: '/metrics'

  - job_name: 'api-gateway'
    static_configs:
      - targets: ['api-gateway:8000']
    metrics_path: '/metrics'
```

#### Grafana Dashboards

```json
{
  "dashboard": {
    "title": "StreetCred Clash Metrics",
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(grpc_requests_total[5m])",
            "legendFormat": "{{method}}"
          }
        ]
      },
      {
        "title": "Error Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(grpc_requests_total{status=\"error\"}[5m])",
            "legendFormat": "{{method}}"
          }
        ]
      }
    ]
  }
}
```

### 6. Security Configuration

#### SSL/TLS Setup

```nginx
# nginx.conf
server {
    listen 443 ssl http2;
    server_name api.streetcredclash.com;

    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;

    location / {
        proxy_pass http://api-gateway:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

#### Firewall Configuration

```bash
# UFW rules
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 50051/tcp # gRPC (internal only)
ufw enable
```

### 7. CI/CD Pipeline

#### GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: |
          docker-compose -f docker-compose.test.yml up --abort-on-container-exit

  deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to production
        run: |
          docker stack deploy -c docker-compose.prod.yml streetcred
```

## Monitoring & Alerting

### Health Checks

```bash
# Service health check script
#!/bin/bash
SERVICES=("core-service" "api-gateway" "postgres" "kafka")

for service in "${SERVICES[@]}"; do
  if ! curl -f http://$service/health; then
    echo "Service $service is down!"
    # Send alert
    curl -X POST -H 'Content-type: application/json' \
      --data "{\"text\":\"Service $service is down!\"}" \
      $SLACK_WEBHOOK_URL
  fi
done
```

### Log Aggregation

```yaml
# docker-compose.prod.yml (add to services)
  fluentd:
    image: fluent/fluentd:v1.14
    volumes:
      - ./fluentd.conf:/fluentd/etc/fluent.conf
    networks:
      - streetcred-network

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.17.0
    environment:
      - discovery.type=single-node
    networks:
      - streetcred-network

  kibana:
    image: docker.elastic.co/kibana/kibana:7.17.0
    ports:
      - "5601:5601"
    networks:
      - streetcred-network
```

## Troubleshooting

### Common Issues

1. **Service won't start**
   ```bash
   # Check logs
   docker-compose logs service-name
   
   # Check resource usage
   docker stats
   ```

2. **Database connection issues**
   ```bash
   # Test connection
   docker-compose exec postgres psql -U streetcred -d streetcred_clash
   
   # Check database status
   docker-compose exec postgres pg_isready
   ```

3. **Kafka connectivity issues**
   ```bash
   # Check Kafka status
   docker-compose exec kafka kafka-topics --list --bootstrap-server localhost:9092
   
   # Test producer/consumer
   docker-compose exec kafka kafka-console-producer --topic test --bootstrap-server localhost:9092
   ```

### Performance Tuning

```bash
# Database optimization
docker-compose exec postgres psql -U streetcred -d streetcred_clash -c "
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = 100;
SELECT pg_reload_conf();
"

# JVM tuning for Kafka
KAFKA_HEAP_OPTS="-Xmx2G -Xms2G"
```

## Backup & Recovery

### Backup Strategy

```bash
#!/bin/bash
# backup.sh

# Database backup
pg_dump -h $DB_HOST -U $DB_USER -d streetcred_clash > backup_$(date +%Y%m%d).sql

# Configuration backup
tar -czf config_backup_$(date +%Y%m%d).tar.gz .env docker-compose*.yml

# Upload to cloud storage
aws s3 cp backup_$(date +%Y%m%d).sql s3://streetcred-backups/
aws s3 cp config_backup_$(date +%Y%m%d).tar.gz s3://streetcred-backups/
```

### Recovery Procedure

```bash
#!/bin/bash
# recovery.sh

# Stop services
docker-compose down

# Restore database
psql -h $DB_HOST -U $DB_USER -d streetcred_clash < backup_20231201.sql

# Restore configuration
tar -xzf config_backup_20231201.tar.gz

# Restart services
docker-compose up -d
```

## Scaling

### Horizontal Scaling

```bash
# Scale core service
docker service scale streetcred_core-service=5

# Scale API gateway
docker service scale streetcred_api-gateway=3
```

### Load Balancing

```nginx
# nginx.conf (load balancer)
upstream core_services {
    server core-service-1:50051;
    server core-service-2:50051;
    server core-service-3:50051;
}

upstream api_services {
    server api-gateway-1:8000;
    server api-gateway-2:8000;
    server api-gateway-3:8000;
}
```

---

This deployment guide provides a comprehensive approach to deploying StreetCred Clash in both development and production environments. Follow the security best practices and monitor your deployment closely. 