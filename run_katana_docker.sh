#!/bin/bash

# Enhanced Katana Docker Runner with Error Handling and Performance Optimization
set -e  # Exit on any error

# Configuration
KATANA_PORT=5050
KATANA_CONTAINER="katana"
KATANA_IMAGE="ghcr.io/dojoengine/katana:v1.5.4"
DOCKER_VOLUME="katana-data"
MAX_RETRIES=3
HEALTH_CHECK_TIMEOUT=30

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker daemon is not running. Please start Docker Desktop and try again."
        print_status "Recommended Docker Desktop settings for Apple Silicon:"
        echo "  - CPUs: 4-8 cores"
        echo "  - Memory: 8-16 GB"
        echo "  - Swap: 2-4 GB"
        exit 1
    fi
    print_success "Docker is running"
}

# Function to wait for Docker Desktop to be ready
wait_for_docker() {
    print_status "Waiting for Docker Desktop to initialize..."
    local attempts=0
    while [ $attempts -lt 30 ]; do
        if docker ps > /dev/null 2>&1; then
            print_success "Docker Desktop is ready"
            return 0
        fi
        echo -n "."
        sleep 2
        attempts=$((attempts + 1))
    done
    print_error "Docker Desktop failed to initialize within 60 seconds"
    exit 1
}

# Function to check if port is available
check_port() {
    if lsof -i :$KATANA_PORT > /dev/null 2>&1; then
        print_warning "Port $KATANA_PORT is already in use"
        print_status "Stopping existing Katana container..."
        docker rm -f $KATANA_CONTAINER 2>/dev/null || true
        sleep 2
    fi
}

# Function to start Katana with retry logic
start_katana() {
    local retry_count=0
    
    while [ $retry_count -lt $MAX_RETRIES ]; do
        print_status "Starting Katana (attempt $((retry_count + 1))/$MAX_RETRIES)..."
        
        # Run Katana container with optimized settings
        docker run -d \
            --name $KATANA_CONTAINER \
            --restart unless-stopped \
            -p $KATANA_PORT:$KATANA_PORT \
            -p 8080:8080 \
            -v $DOCKER_VOLUME:/root/.local/share/katana \
            --memory="4g" \
            --cpus="2.0" \
            $KATANA_IMAGE \
            katana \
            --dev \
            --dev.accounts 3 \
            --dev.seed 0x1234567890abcdef \
            --http.addr 0.0.0.0 \
            --http.port $KATANA_PORT \
            --block-time 1000
        
        # Wait for container to start
        sleep 5
        
        # Check if container is running
        if docker ps | grep -q $KATANA_CONTAINER; then
            print_success "Katana container started successfully"
            return 0
        else
            print_warning "Katana container failed to start, retrying..."
            docker rm -f $KATANA_CONTAINER 2>/dev/null || true
            retry_count=$((retry_count + 1))
            sleep 5
        fi
    done
    
    print_error "Failed to start Katana after $MAX_RETRIES attempts"
    exit 1
}

# Function to wait for Katana to be ready
wait_for_katana() {
    print_status "Waiting for Katana RPC to be ready..."
    local attempts=0
    
    while [ $attempts -lt $HEALTH_CHECK_TIMEOUT ]; do
        if curl -s -X POST http://localhost:$KATANA_PORT \
            -H "Content-Type: application/json" \
            -d '{"jsonrpc":"2.0","method":"starknet_chainId","params":[],"id":1}' \
            > /dev/null 2>&1; then
            print_success "Katana RPC is ready"
            return 0
        fi
        
        echo -n "."
        sleep 2
        attempts=$((attempts + 1))
    done
    
    print_error "Katana RPC failed to respond within $HEALTH_CHECK_TIMEOUT seconds"
    print_status "Checking container logs..."
    docker logs $KATANA_CONTAINER --tail 20
    exit 1
}

# Function to test RPC functionality
test_rpc() {
    print_status "Testing RPC functionality..."
    
    # Test chain ID
    local chain_id=$(curl -s -X POST http://localhost:$KATANA_PORT \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"starknet_chainId","params":[],"id":1}' \
        | jq -r '.result' 2>/dev/null)
    
    if [ "$chain_id" = "0x4b4154414e41" ]; then
        print_success "Chain ID test passed: $(echo $chain_id | xxd -r -p)"
    else
        print_error "Chain ID test failed: $chain_id"
        return 1
    fi
    
    # Test block number
    local block_number=$(curl -s -X POST http://localhost:$KATANA_PORT \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"starknet_blockNumber","params":[],"id":1}' \
        | jq -r '.result' 2>/dev/null)
    
    if [ -n "$block_number" ] && [ "$block_number" != "null" ]; then
        print_success "Block number test passed: $block_number"
    else
        print_error "Block number test failed: $block_number"
        return 1
    fi
}

# Function to display account information
show_accounts() {
    print_status "Extracting account information..."
    
    # Get account info from container logs
    docker logs $KATANA_CONTAINER 2>&1 | grep -E "(Account address|Private key|Public key)" > katana_accounts.log
    
    if [ -s katana_accounts.log ]; then
        print_success "Account information saved to katana_accounts.log"
        echo ""
        echo "🎉 Account Summary:"
        echo "=================="
        cat katana_accounts.log
    else
        print_warning "Could not extract account information from logs"
    fi
}

# Function to display status and next steps
show_status() {
    echo ""
    echo "🎉 Katana is running successfully!"
    echo "=================================="
    echo ""
    echo "📊 RPC URL: http://localhost:$KATANA_PORT"
    echo "🔗 Explorer: http://localhost:$KATANA_PORT/explorer"
    echo "📝 Logs: docker logs -f $KATANA_CONTAINER"
    echo "🛑 Stop: docker stop $KATANA_CONTAINER"
    echo "🔄 Restart: docker restart $KATANA_CONTAINER"
    echo ""
    echo "💡 Performance Tips:"
    echo "  - Monitor Docker Desktop resource usage"
    echo "  - Adjust CPU/Memory allocation if needed"
    echo "  - Use 'docker stats $KATANA_CONTAINER' to monitor performance"
    echo ""
    echo "🏥 Troubleshooting:"
    echo "  - If RPC is slow: Increase Docker memory allocation"
    echo "  - If container stops: Check Docker Desktop resources"
    echo "  - If port conflicts: Stop other services using port $KATANA_PORT"
}

# Main execution
main() {
    echo "🚀 Starting Katana Local Devnet Setup"
    echo "====================================="
    echo ""
    
    # Check prerequisites
    check_docker
    wait_for_docker
    check_port
    
    # Start Katana
    start_katana
    wait_for_katana
    
    # Test functionality
    test_rpc
    show_accounts
    
    # Display status
    show_status
}

# Run main function
main "$@" 