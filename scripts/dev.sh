#!/bin/bash

# Development script for Starknet Gamified Perp Proposal
# This script provides convenient commands for working with the Docker development environment

set -e

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

# Function to show usage
show_usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start       - Start all services"
    echo "  stop        - Stop all services"
    echo "  restart     - Restart all services"
    echo "  build       - Build all services"
    echo "  logs        - Show logs for all services"
    echo "  core-logs   - Show logs for core-service only"
    echo "  shell       - Open shell in core-service container"
    echo "  test        - Run tests in core-service"
    echo "  clean       - Stop and remove all containers, networks, and volumes"
    echo "  status      - Show status of all services"
    echo "  help        - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 shell"
    echo "  $0 test"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Function to start services
start_services() {
    print_status "Starting all services..."
    docker-compose up -d
    print_success "All services started successfully!"
    print_status "Services available at:"
    echo "  - Core Service (gRPC): localhost:50051"
    echo "  - API Gateway: localhost:8000"
    echo "  - Persistence Service: localhost:8001"
    echo "  - PostgreSQL: localhost:5432"
    echo "  - Kafka: localhost:9092"
    echo "  - Katana (Starknet): localhost:5050"
    echo "  - Redis: localhost:6379"
}

# Function to stop services
stop_services() {
    print_status "Stopping all services..."
    docker-compose down
    print_success "All services stopped successfully!"
}

# Function to restart services
restart_services() {
    print_status "Restarting all services..."
    docker-compose down
    docker-compose up -d
    print_success "All services restarted successfully!"
}

# Function to build services
build_services() {
    print_status "Building all services..."
    docker-compose build --no-cache
    print_success "All services built successfully!"
}

# Function to show logs
show_logs() {
    print_status "Showing logs for all services..."
    docker-compose logs -f
}

# Function to show core-service logs
show_core_logs() {
    print_status "Showing logs for core-service..."
    docker-compose logs -f core-service
}

# Function to open shell in core-service
open_shell() {
    print_status "Opening shell in core-service container..."
    docker-compose exec core-service /bin/bash
}

# Function to run tests
run_tests() {
    print_status "Running tests in core-service..."
    docker-compose exec core-service cargo test
}

# Function to clean everything
clean_all() {
    print_warning "This will remove all containers, networks, and volumes. Are you sure? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        print_status "Cleaning all Docker resources..."
        docker-compose down -v --remove-orphans
        docker system prune -f
        print_success "All Docker resources cleaned successfully!"
    else
        print_status "Clean operation cancelled."
    fi
}

# Function to show status
show_status() {
    print_status "Service status:"
    docker-compose ps
}

# Main script logic
main() {
    # Check if Docker is running
    check_docker
    
    # Parse command
    case "${1:-help}" in
        start)
            start_services
            ;;
        stop)
            stop_services
            ;;
        restart)
            restart_services
            ;;
        build)
            build_services
            ;;
        logs)
            show_logs
            ;;
        core-logs)
            show_core_logs
            ;;
        shell)
            open_shell
            ;;
        test)
            run_tests
            ;;
        clean)
            clean_all
            ;;
        status)
            show_status
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_error "Unknown command: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 