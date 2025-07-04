# Deployment Guide

## Overview

This guide covers deploying the Starknet gamified perpetual trading platform to various environments, including local development, testnets, and mainnet.

## 🏗️ Architecture Overview

### Deployment Components

```
Deployment Pipeline
├── Smart Contracts (Cairo)
│   ├── Local Katana
│   ├── Testnet (Goerli/Testnet2)
│   └── Mainnet
├── Frontend (Flutter)
│   ├── Web Build
│   ├── Mobile Apps
│   └── CDN Distribution
└── Backend Services
    ├── API Gateway
    ├── Core Service
    └── Persistence Service
```

## 📜 Contract Deployment

### Prerequisites

- **Scarb**: Cairo package manager
- **Starkli**: Starknet CLI tool
- **Katana**: Local development environment
- **Wallet**: Funded account for deployment

### Environment Setup

```bash
# Install Scarb
curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh

# Install Starkli
curl -L https://raw.githubusercontent.com/xJonathanLEI/starkli/main/install.sh | sh

# Verify installations
scarb --version
starkli --version
```

### Local Deployment

```bash
# 1. Start Katana
./run_katana_docker.sh

# 2. Build contracts
cd contracts
scarb build

# 3. Deploy to local Katana
scarb deploy --target katana

# 4. Verify deployment
scarb deploy --show-addresses
```

### Testnet Deployment

```bash
# 1. Configure testnet environment
export STARKNET_RPC_URL="https://alpha4.starknet.io"
export STARKNET_CHAIN_ID="SN_GOERLI"

# 2. Build contracts
cd contracts
scarb build

# 3. Deploy to testnet
scarb deploy --target testnet

# 4. Verify on explorer
# Visit: https://testnet.starkscan.co
```

### Mainnet Deployment

```bash
# 1. Configure mainnet environment
export STARKNET_RPC_URL="https://alpha-mainnet.starknet.io"
export STARKNET_CHAIN_ID="SN_MAIN"

# 2. Build contracts
cd contracts
scarb build

# 3. Deploy to mainnet
scarb deploy --target mainnet

# 4. Verify on explorer
# Visit: https://starkscan.co
```

### Deployment Script

```bash
#!/bin/bash
# scripts/deploy.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
ENVIRONMENT=${1:-local}
CONTRACT_NAME=${2:-scdrip}

echo -e "${YELLOW}🚀 Deploying $CONTRACT_NAME to $ENVIRONMENT${NC}"

# Validate environment
case $ENVIRONMENT in
  local|testnet|mainnet)
    ;;
  *)
    echo -e "${RED}❌ Invalid environment: $ENVIRONMENT${NC}"
    echo "Usage: $0 [local|testnet|mainnet] [contract_name]"
    exit 1
    ;;
esac

# Set environment variables
case $ENVIRONMENT in
  local)
    export STARKNET_RPC_URL="http://localhost:5050"
    export STARKNET_CHAIN_ID="SN_GOERLI"
    ;;
  testnet)
    export STARKNET_RPC_URL="https://alpha4.starknet.io"
    export STARKNET_CHAIN_ID="SN_GOERLI"
    ;;
  mainnet)
    export STARKNET_RPC_URL="https://alpha-mainnet.starknet.io"
    export STARKNET_CHAIN_ID="SN_MAIN"
    ;;
esac

# Build contracts
echo -e "${YELLOW}📦 Building contracts...${NC}"
cd contracts
scarb build

# Deploy contracts
echo -e "${YELLOW}🚀 Deploying contracts...${NC}"
scarb deploy --target $ENVIRONMENT

# Get deployment addresses
echo -e "${YELLOW}📋 Deployment addresses:${NC}"
scarb deploy --show-addresses

# Verify deployment
echo -e "${YELLOW}✅ Verifying deployment...${NC}"
if [ "$ENVIRONMENT" != "local" ]; then
  # Wait for deployment to be confirmed
  sleep 30
  
  # Verify on explorer
  case $ENVIRONMENT in
    testnet)
      echo "🔍 View on testnet explorer: https://testnet.starkscan.co"
      ;;
    mainnet)
      echo "🔍 View on mainnet explorer: https://starkscan.co"
      ;;
  esac
fi

echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
```

## 📱 Frontend Deployment

### Web Deployment

#### Build Process

```bash
# 1. Install dependencies
cd frontend
flutter pub get

# 2. Build web version
flutter build web --release

# 3. Deploy to hosting service
# Options: Firebase Hosting, Netlify, Vercel, etc.
```

#### Firebase Hosting

```bash
# 1. Install Firebase CLI
npm install -g firebase-tools

# 2. Initialize Firebase
firebase init hosting

# 3. Build and deploy
flutter build web --release
firebase deploy --only hosting
```

#### Netlify Deployment

```bash
# 1. Create netlify.toml
cat > netlify.toml << EOF
[build]
  publish = "build/web"
  command = "cd frontend && flutter build web --release"

[build.environment]
  FLUTTER_VERSION = "3.x"
EOF

# 2. Deploy
netlify deploy --prod
```

### Mobile App Deployment

#### iOS App Store

```bash
# 1. Build iOS app
cd frontend
flutter build ios --release

# 2. Archive and upload
# Use Xcode to archive and upload to App Store Connect
```

#### Android Play Store

```bash
# 1. Build Android app
cd frontend
flutter build appbundle --release

# 2. Upload to Play Console
# Use Google Play Console to upload the .aab file
```

### Environment Configuration

```dart
// lib/core/config/environment.dart
class Environment {
  static const String starknetRpcUrl = String.fromEnvironment(
    'STARKNET_RPC_URL',
    defaultValue: 'https://alpha-mainnet.starknet.io',
  );

  static const String contractAddress = String.fromEnvironment(
    'CONTRACT_ADDRESS',
    defaultValue: '',
  );

  static const bool isProduction = bool.fromEnvironment(
    'IS_PRODUCTION',
    defaultValue: false,
  );
}
```

## 🔧 Backend Services Deployment

### Docker Compose Setup

```yaml
# docker/docker-compose.prod.yml
version: '3.8'

services:
  api-gateway:
    build:
      context: ./services/api-gateway
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    environment:
      - ENVIRONMENT=production
      - STARKNET_RPC_URL=${STARKNET_RPC_URL}
    depends_on:
      - core-service

  core-service:
    build:
      context: ./services/core-service
      dockerfile: Dockerfile
    ports:
      - "8001:8001"
    environment:
      - ENVIRONMENT=production
      - DATABASE_URL=${DATABASE_URL}

  persistence-service:
    build:
      context: ./services/persistence-service
      dockerfile: Dockerfile
    ports:
      - "8002:8002"
    environment:
      - ENVIRONMENT=production
      - DATABASE_URL=${DATABASE_URL}
    volumes:
      - postgres_data:/var/lib/postgresql/data

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - api-gateway
      - core-service
      - persistence-service

volumes:
  postgres_data:
```

### Kubernetes Deployment

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: starknet-gamified-perp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: starknet-gamified-perp
  template:
    metadata:
      labels:
        app: starknet-gamified-perp
    spec:
      containers:
      - name: api-gateway
        image: your-registry/api-gateway:latest
        ports:
        - containerPort: 8000
        env:
        - name: ENVIRONMENT
          value: "production"
        - name: STARKNET_RPC_URL
          valueFrom:
            secretKeyRef:
              name: starknet-secrets
              key: rpc-url

---
apiVersion: v1
kind: Service
metadata:
  name: starknet-gamified-perp-service
spec:
  selector:
    app: starknet-gamified-perp
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8000
  type: LoadBalancer
```

## 🔄 CI/CD Pipeline

### GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Cairo
        run: |
          curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh
          echo "$HOME/.local/bin" >> $GITHUB_PATH
      
      - name: Test contracts
        run: |
          cd contracts
          scarb test
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      
      - name: Test frontend
        run: |
          cd frontend
          flutter test

  deploy-contracts:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Cairo
        run: |
          curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh
          echo "$HOME/.local/bin" >> $GITHUB_PATH
      
      - name: Deploy to testnet
        env:
          STARKNET_RPC_URL: ${{ secrets.STARKNET_RPC_URL }}
          STARKNET_PRIVATE_KEY: ${{ secrets.STARKNET_PRIVATE_KEY }}
        run: |
          cd contracts
          scarb deploy --target testnet
      
      - name: Update contract addresses
        run: |
          # Update frontend with new contract addresses
          echo "CONTRACT_ADDRESS=${{ steps.deploy.outputs.contract_address }}" >> $GITHUB_ENV

  deploy-frontend:
    needs: deploy-contracts
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      
      - name: Build web
        run: |
          cd frontend
          flutter build web --release
      
      - name: Deploy to Firebase
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          projectId: your-project-id
          channelId: live

  deploy-backend:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      
      - name: Build and push Docker images
        run: |
          docker build -t your-registry/api-gateway:${{ github.sha }} ./services/api-gateway
          docker build -t your-registry/core-service:${{ github.sha }} ./services/core-service
          docker build -t your-registry/persistence-service:${{ github.sha }} ./services/persistence-service
          
          docker push your-registry/api-gateway:${{ github.sha }}
          docker push your-registry/core-service:${{ github.sha }}
          docker push your-registry/persistence-service:${{ github.sha }}
      
      - name: Deploy to Kubernetes
        run: |
          kubectl set image deployment/starknet-gamified-perp api-gateway=your-registry/api-gateway:${{ github.sha }}
          kubectl set image deployment/starknet-gamified-perp core-service=your-registry/core-service:${{ github.sha }}
          kubectl set image deployment/starknet-gamified-perp persistence-service=your-registry/persistence-service:${{ github.sha }}
```

### GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - test
  - build
  - deploy

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"

test:
  stage: test
  image: ubuntu:latest
  before_script:
    - curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh
    - export PATH="$HOME/.local/bin:$PATH"
  script:
    - cd contracts
    - scarb test
    - cd ../frontend
    - flutter test

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA

deploy:
  stage: deploy
  image: alpine:latest
  before_script:
    - apk add --no-cache curl
  script:
    - curl -X POST $DEPLOY_WEBHOOK -H "Content-Type: application/json" -d "{\"commit\": \"$CI_COMMIT_SHA\"}"
  only:
    - main
```

## 🔒 Security Considerations

### Environment Variables

```bash
# .env.production
STARKNET_RPC_URL=https://alpha-mainnet.starknet.io
STARKNET_CHAIN_ID=SN_MAIN
CONTRACT_ADDRESS=0x...
DATABASE_URL=postgresql://user:pass@host:port/db
JWT_SECRET=your-jwt-secret
API_KEY=your-api-key
```

### Secrets Management

```bash
# Kubernetes secrets
kubectl create secret generic starknet-secrets \
  --from-literal=rpc-url=https://alpha-mainnet.starknet.io \
  --from-literal=private-key=your-private-key

# Docker secrets
docker secret create starknet_private_key ./private_key.txt
```

### SSL/TLS Configuration

```nginx
# nginx.conf
server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    ssl_prefer_server_ciphers off;
    
    location / {
        proxy_pass http://api-gateway:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## 📊 Monitoring and Logging

### Health Checks

```bash
#!/bin/bash
# scripts/health_check.sh

# Check contract deployment
curl -X POST $STARKNET_RPC_URL \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"starknet_getClassAt","params":{"block_number":"latest","contract_address":"'$CONTRACT_ADDRESS'"},"id":1}'

# Check API health
curl -f http://localhost:8000/health

# Check database connectivity
pg_isready -h $DB_HOST -p $DB_PORT -U $DB_USER
```

### Logging Configuration

```yaml
# docker-compose.prod.yml
services:
  api-gateway:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
  
  core-service:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

### Metrics Collection

```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'starknet-gamified-perp'
    static_configs:
      - targets: ['api-gateway:8000', 'core-service:8001']
    metrics_path: /metrics
```

## 🚀 Rollback Strategy

### Contract Rollback

```bash
#!/bin/bash
# scripts/rollback.sh

CONTRACT_ADDRESS=$1
PREVIOUS_VERSION=$2

if [ -z "$CONTRACT_ADDRESS" ] || [ -z "$PREVIOUS_VERSION" ]; then
    echo "Usage: $0 <contract_address> <previous_version>"
    exit 1
fi

# Deploy previous version
cd contracts
git checkout $PREVIOUS_VERSION
scarb build
scarb deploy --target mainnet

echo "Rolled back to version $PREVIOUS_VERSION"
```

### Frontend Rollback

```bash
# Rollback to previous deployment
firebase hosting:clone your-project:live:previous your-project:live

# Or rollback Docker image
kubectl rollout undo deployment/starknet-gamified-perp
```

## 📋 Deployment Checklist

### Pre-deployment

- [ ] All tests passing
- [ ] Security audit completed
- [ ] Performance testing done
- [ ] Documentation updated
- [ ] Environment variables configured
- [ ] Secrets properly stored
- [ ] Backup strategy in place

### Deployment

- [ ] Deploy to staging first
- [ ] Run smoke tests
- [ ] Deploy to production
- [ ] Verify all services are running
- [ ] Check monitoring dashboards
- [ ] Update DNS/load balancer
- [ ] Notify stakeholders

### Post-deployment

- [ ] Monitor error rates
- [ ] Check performance metrics
- [ ] Verify user functionality
- [ ] Update documentation
- [ ] Archive deployment artifacts
- [ ] Schedule post-mortem if needed

## 📚 Additional Resources

- [Starknet Documentation](https://docs.starknet.io/)
- [Scarb Documentation](https://docs.swmansion.com/scarb/)
- [Flutter Deployment Guide](https://flutter.dev/docs/deployment)
- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/) 