#!/bin/bash

echo "🎮 StreetCred Clash - Game Testing Script"
echo "========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}📋 Testing Components Available:${NC}"
echo ""
echo "1. 🎨 Frontend Flutter App (Mobile UI)"
echo "2. 🔧 API Gateway (WebSocket + GraphQL)"
echo "3. ⚙️  Core Service (Game Logic + Redis)"
echo "4. 🌐 WebSocket Real-time Events"
echo "5. 🧪 Manual Testing Tools"
echo ""

# Check if required tools are available
echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"

# Check Flutter
if command -v flutter &> /dev/null; then
    echo -e "${GREEN}✅ Flutter found$(flutter --version | head -n 1)${NC}"
else
    echo -e "${RED}❌ Flutter not found. Please install Flutter first.${NC}"
    exit 1
fi

# Check Rust/Cargo
if command -v cargo &> /dev/null; then
    echo -e "${GREEN}✅ Rust/Cargo found$(cargo --version)${NC}"
else
    echo -e "${RED}❌ Rust/Cargo not found. Please install Rust first.${NC}"
    exit 1
fi

# Check Python
if command -v python3 &> /dev/null; then
    echo -e "${GREEN}✅ Python found$(python3 --version)${NC}"
else
    echo -e "${RED}❌ Python not found. Please install Python first.${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🚀 Quick Start Options:${NC}"
echo ""
echo "A. Start Frontend Only (Mock Mode)"
echo "B. Start Full Stack (Frontend + Backend)"
echo "C. Test WebSocket Events"
echo "D. Test Individual Components"
echo ""

read -p "Choose option (A/B/C/D): " choice

case $choice in
    [Aa]*)
        echo ""
        echo -e "${YELLOW}🎨 Starting Frontend in Mock Mode...${NC}"
        echo ""
        echo "This will run the Flutter app with mock data."
        echo "You can test:"
        echo "- Swipe gestures in Trade Arena"
        echo "- NFT inventory animations"
        echo "- Reward celebrations"
        echo "- UI interactions with haptic feedback"
        echo ""
        read -p "Continue? (y/n): " confirm
        if [[ $confirm == [Yy]* ]]; then
            cd frontend
            echo -e "${GREEN}📱 Launching Flutter app...${NC}"
            flutter run -d chrome --web-port 3000
        fi
        ;;
    [Bb]*)
        echo ""
        echo -e "${YELLOW}🏗️ Starting Full Stack...${NC}"
        echo ""
        echo "This requires Docker or manual service startup."
        echo "Services needed:"
        echo "- Redis (for WebSocket events)"
        echo "- PostgreSQL (for game data)"
        echo "- Core Service (Rust)"
        echo "- API Gateway (Python)"
        echo ""
        echo "Option 1: Use Docker Compose"
        echo "Option 2: Manual startup"
        echo ""
        read -p "Use Docker? (y/n): " docker_choice
        if [[ $docker_choice == [Yy]* ]]; then
            echo -e "${GREEN}🐳 Starting with Docker...${NC}"
            docker-compose up -d redis postgres
            sleep 3
            echo "Services starting... Check with: docker-compose ps"
        else
            echo -e "${BLUE}📋 Manual Startup Instructions:${NC}"
            echo ""
            echo "1. Start Redis: redis-server"
            echo "2. Start PostgreSQL: pg_ctl start"
            echo "3. Start Core Service: cd services/core-service && cargo run"
            echo "4. Start API Gateway: cd services/api-gateway && python -m uvicorn src.main:app --reload --port 8080"
            echo "5. Start Frontend: cd frontend && flutter run"
        fi
        ;;
    [Cc]*)
        echo ""
        echo -e "${YELLOW}🌐 Testing WebSocket Events...${NC}"
        echo ""
        echo "This will test the real-time event system."
        echo ""
        echo "First, let's check if the API Gateway test endpoint works:"
        echo ""
        curl -X POST "http://localhost:8080/test/emit-event?event_type=xp.earned&player_id=test-player" 2>/dev/null || echo -e "${RED}❌ API Gateway not running. Start it first with: cd services/api-gateway && python -m uvicorn src.main:app --reload --port 8080${NC}"
        ;;
    [Dd]*)
        echo ""
        echo -e "${YELLOW}🧪 Component Testing Menu${NC}"
        echo ""
        echo "1. Test Core Service (Rust)"
        echo "2. Test API Gateway (Python)"
        echo "3. Test Frontend (Flutter)"
        echo "4. Test WebSocket Connection"
        echo "5. Test Game Logic"
        echo ""
        read -p "Choose component (1-5): " component
        
        case $component in
            1)
                echo -e "${GREEN}⚙️ Testing Core Service...${NC}"
                cd services/core-service
                cargo check
                ;;
            2)
                echo -e "${GREEN}🔧 Testing API Gateway...${NC}"
                cd services/api-gateway
                python -c "import sys; print('Python version:', sys.version)"
                pip list | grep -E "(fastapi|uvicorn|aioredis)"
                ;;
            3)
                echo -e "${GREEN}📱 Testing Frontend...${NC}"
                cd frontend
                flutter doctor
                flutter test
                ;;
            4)
                echo -e "${GREEN}🌐 Testing WebSocket...${NC}"
                echo "Checking WebSocket endpoint..."
                curl -I http://localhost:8080/ws/game-events 2>/dev/null || echo "WebSocket endpoint not available"
                ;;
            5)
                echo -e "${GREEN}🎮 Testing Game Logic...${NC}"
                cd services/core-service
                cargo test
                ;;
        esac
        ;;
    *)
        echo -e "${RED}Invalid option. Please choose A, B, C, or D.${NC}"
        ;;
esac

echo ""
echo -e "${BLUE}📱 Frontend Testing URLs (when running):${NC}"
echo ""
echo "• Flutter Web: http://localhost:3000"
echo "• API Gateway: http://localhost:8080"
echo "• Health Check: http://localhost:8080/healthz"
echo "• GraphQL: http://localhost:8080/graphql"
echo "• WebSocket: ws://localhost:8080/ws/game-events"
echo ""
echo -e "${BLUE}🧪 Manual Testing Tips:${NC}"
echo ""
echo "1. Trade Arena: Try swiping up/down with different speeds"
echo "2. Drip Inventory: Tap NFTs to equip them"
echo "3. Streak System: Check the streaks page"
echo "4. Real-time Events: Watch for XP/NFT notifications"
echo "5. WebSocket Test: POST to /test/emit-event"
echo ""
echo -e "${GREEN}✨ Happy Testing!${NC}"