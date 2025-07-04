#!/bin/bash

set -e

echo "🚀 Starting local CI test suite..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
START_TIME=$(date +%s)

# Function to run test and track results
run_test() {
    local test_name="$1"
    local test_command="$2"
    local test_timeout="${3:-300}" # Default 5 minutes timeout
    
    echo -e "${YELLOW}Running: $test_name${NC}"
    echo "Command: $test_command"
    echo "Timeout: ${test_timeout}s"
    echo "----------------------------------------"
    
    local start_time=$(date +%s)
    
    if timeout $test_timeout bash -c "$test_command"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        echo -e "${GREEN}✅ $test_name passed (${duration}s)${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        echo -e "${RED}❌ $test_name failed (${duration}s)${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check system requirements
check_requirements() {
    echo -e "${BLUE}🔍 Checking system requirements...${NC}"
    
    local missing_deps=()
    
    # Check for required tools
    if ! command_exists docker; then
        missing_deps+=("docker")
    fi
    
    if ! command_exists scarb; then
        missing_deps+=("scarb")
    fi
    
    if ! command_exists flutter; then
        missing_deps+=("flutter")
    fi
    
    if ! command_exists curl; then
        missing_deps+=("curl")
    fi
    
    if ! command_exists jq; then
        missing_deps+=("jq")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${RED}❌ Missing dependencies: ${missing_deps[*]}${NC}"
        echo "Please install the missing dependencies and try again."
        exit 1
    fi
    
    echo -e "${GREEN}✅ All dependencies found${NC}"
}

# Check if Katana is running
check_katana() {
    echo -e "${BLUE}🔍 Checking Katana status...${NC}"
    
    if curl -s -X POST http://localhost:5050 \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"starknet_chainId","params":[],"id":1}' > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Katana is running${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Katana is not running${NC}"
        return 1
    fi
}

# Start Katana if not running
start_katana() {
    if ! check_katana; then
        echo -e "${YELLOW}🚀 Starting Katana...${NC}"
        if [ -f "./run_katana_docker.sh" ]; then
            ./run_katana_docker.sh
            sleep 10
            check_katana
        else
            echo -e "${RED}❌ Katana startup script not found${NC}"
            return 1
        fi
    fi
}

# Function to generate test report
generate_report() {
    local end_time=$(date +%s)
    local total_duration=$((end_time - START_TIME))
    
    echo ""
    echo "📊 Test Summary"
    echo "==============="
    echo -e "${GREEN}✅ Tests Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}❌ Tests Failed: $TESTS_FAILED${NC}"
    echo "⏱️  Total Duration: ${total_duration}s"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}💥 Some tests failed. Please check the output above.${NC}"
        return 1
    fi
}

# Function to clean up resources
cleanup() {
    echo -e "${BLUE}🧹 Cleaning up...${NC}"
    
    # Stop any running containers (optional)
    # docker stop $(docker ps -q --filter "name=test-*") 2>/dev/null || true
    
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

# Set up trap to run cleanup on exit
trap cleanup EXIT

# Main test execution
main() {
    echo "📋 Test Suite Configuration:"
    echo "  - Cairo: 2.8.0"
    echo "  - Scarb: 2.8.0"
    echo "  - Katana: 1.5.4"
    echo "  - Flutter: 3.x"
    echo "  - Platform: $(uname -s) $(uname -m)"
    echo ""

    # Check requirements
    check_requirements
    
    # Start Katana
    start_katana

    # Contract tests
    echo ""
    echo "🏗️  Contract Tests"
    echo "=================="
    
    run_test "Contract Build" "cd contracts && scarb build"
    run_test "Contract Unit Tests" "cd contracts && scarb test"
    run_test "Contract Gas Tests" "cd contracts && scarb test --gas"
    
    # Frontend tests
    echo ""
    echo "📱 Frontend Tests"
    echo "================="
    
    run_test "Frontend Dependencies" "cd frontend && flutter pub get"
    run_test "Frontend Unit Tests" "cd frontend && flutter test"
    run_test "Frontend Build" "cd frontend && flutter build web --release"
    
    # Integration tests
    echo ""
    echo "🔗 Integration Tests"
    echo "===================="
    
    run_test "Contract Deployment" "cd contracts && scarb deploy"
    run_test "RPC Connectivity" "curl -s -X POST http://localhost:5050 -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"starknet_chainId\",\"params\":[],\"id\":1}' | jq -r '.result'"
    
    # Performance tests
    echo ""
    echo "⚡ Performance Tests"
    echo "==================="
    
    if [ -f "contracts/scripts/gas_benchmark.sh" ]; then
        run_test "Gas Benchmark" "cd contracts && ./scripts/gas_benchmark.sh"
    else
        echo -e "${YELLOW}⚠️  Gas benchmark script not found, skipping${NC}"
    fi
    
    if [ -f "scripts/load_test.sh" ]; then
        run_test "Load Test" "./scripts/load_test.sh"
    else
        echo -e "${YELLOW}⚠️  Load test script not found, skipping${NC}"
    fi
    
    # Security tests
    echo ""
    echo "🔒 Security Tests"
    echo "================="
    
    run_test "Dependency Audit" "cd contracts && scarb audit" 60
    run_test "Code Analysis" "cd contracts && scarb fmt --check"
    
    # Generate final report
    generate_report
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --help, -h     Show this help message"
            echo "  --contracts    Run only contract tests"
            echo "  --frontend     Run only frontend tests"
            echo "  --integration  Run only integration tests"
            echo "  --performance  Run only performance tests"
            echo "  --security     Run only security tests"
            echo "  --no-katana    Skip Katana startup"
            echo ""
            echo "Examples:"
            echo "  $0                    # Run all tests"
            echo "  $0 --contracts        # Run only contract tests"
            echo "  $0 --frontend --no-katana  # Run frontend tests without Katana"
            exit 0
            ;;
        --contracts)
            echo "Running only contract tests..."
            # Contract tests only
            check_requirements
            start_katana
            run_test "Contract Build" "cd contracts && scarb build"
            run_test "Contract Unit Tests" "cd contracts && scarb test"
            run_test "Contract Gas Tests" "cd contracts && scarb test --gas"
            generate_report
            exit $?
            ;;
        --frontend)
            echo "Running only frontend tests..."
            # Frontend tests only
            check_requirements
            run_test "Frontend Dependencies" "cd frontend && flutter pub get"
            run_test "Frontend Unit Tests" "cd frontend && flutter test"
            run_test "Frontend Build" "cd frontend && flutter build web --release"
            generate_report
            exit $?
            ;;
        --integration)
            echo "Running only integration tests..."
            # Integration tests only
            check_requirements
            start_katana
            run_test "Contract Deployment" "cd contracts && scarb deploy"
            run_test "RPC Connectivity" "curl -s -X POST http://localhost:5050 -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"starknet_chainId\",\"params\":[],\"id\":1}' | jq -r '.result'"
            generate_report
            exit $?
            ;;
        --performance)
            echo "Running only performance tests..."
            # Performance tests only
            check_requirements
            start_katana
            if [ -f "contracts/scripts/gas_benchmark.sh" ]; then
                run_test "Gas Benchmark" "cd contracts && ./scripts/gas_benchmark.sh"
            fi
            if [ -f "scripts/load_test.sh" ]; then
                run_test "Load Test" "./scripts/load_test.sh"
            fi
            generate_report
            exit $?
            ;;
        --security)
            echo "Running only security tests..."
            # Security tests only
            check_requirements
            run_test "Dependency Audit" "cd contracts && scarb audit" 60
            run_test "Code Analysis" "cd contracts && scarb fmt --check"
            generate_report
            exit $?
            ;;
        --no-katana)
            echo "Skipping Katana startup..."
            # Modify the start_katana function to do nothing
            start_katana() {
                echo -e "${YELLOW}⚠️  Katana startup skipped${NC}"
                return 0
            }
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
    shift
done

# Run main function if no specific test type was specified
if [ $# -eq 0 ]; then
    main
fi 