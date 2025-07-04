# Backend Architecture Overview

## 🏗️ System Architecture

The StreetCred Clash backend is built around a **GameEngine** core that orchestrates all gameplay logic, cleanly separated from infrastructure concerns. This modular design ensures testability, scalability, and maintainability.

## 🎯 Core Components

### GameEngine (`game_engine/game_engine.rs`)

The central orchestrator that coordinates all gameplay operations:

```rust
pub struct GameEngine {
    pub starknet: StarknetClient,      // Blockchain interactions
    pub publisher: KafkaProducer,      // Event streaming
    pub conquest: TileService,         // Tile/territory logic
    pub streaks: StreakService,        // Streak management
    pub pvp: PvPService,              // Player vs Player combat
    pub rewards: RewardService,        // NFT/ink rewards
    pub db: Database,                  // Data persistence
}
```

**Key Method:**
```rust
pub async fn process_move(&self, player_id: String, move_data: MoveData) -> Result<RewardSummary>
```

This method orchestrates the complete move flow:
1. **Validate** the move (tile logic)
2. **Update** player position/state
3. **Mint** NFT if eligible (rewards)
4. **Update** streaks
5. **Publish** events (Kafka)
6. **Return** summary of actions taken

## 🧩 Service Modules

### TileService (`game_engine/tile.rs`)
Handles tile-based gameplay mechanics:
- **`validate_tile_move()`** - Ensures move is valid
- **`update_player_position()`** - Updates player location
- Territory conquest logic
- Resource harvesting

### RewardService (`game_engine/rewards.rs`)
Manages player rewards and NFTs:
- **`mint_drip_nft()`** - Mints NFTs on blockchain
- Ink reward calculations
- Achievement unlocks

### StreakService (`game_engine/streak.rs`)
Tracks and manages player streaks:
- **`update_streak()`** - Increments streak counters
- Daily/weekly streak logic
- Streak-based rewards

### PvPService (`game_engine/pvp.rs`)
Handles player vs player combat:
- Match creation and management
- Combat resolution
- Leaderboards

## 🏗️ Infrastructure Layer

### StarknetClient (`infra/starknet.rs`)
Blockchain interactions:
- Smart contract calls
- Transaction submission
- Event listening

### KafkaProducer (`infra/kafka.rs`)
Event streaming:
- **`send_player_move()`** - Player movement events
- **`send_tile_interaction()`** - Tile interaction events
- **`send_pvp_match()`** - PvP match events
- **`send_streak_update()`** - Streak update events

### Database (`infra/db.rs`)
Data persistence:
- Player state storage
- Tile ownership records
- PvP match history
- Streak tracking

## 🔄 Request Flow

### 1. gRPC Request
```
Client → gRPC Handler → GameEngine::process_move()
```

### 2. GameEngine Orchestration
```
process_move() {
    validate_tile_move()     → TileService
    update_player_position() → TileService
    mint_drip_nft()         → RewardService
    update_streak()         → StreakService
    send_player_move()      → KafkaProducer
}
```

### 3. Side Effects
- **Blockchain**: NFT minting via StarknetClient
- **Events**: Kafka messages for real-time updates
- **Database**: Player/tile state updates
- **Response**: RewardSummary with all actions taken

## 🧪 Testing Strategy

### Unit Tests (`tests/game_engine_tests.rs`)
- **Mocked dependencies** for isolated testing
- **Test scenarios**:
  - ✅ Successful move rewards NFT and updates tile
  - ✅ Invalid tile does not emit events
  - ✅ Streak incremented on valid move
  - ✅ NFT mint failure handled gracefully
  - ✅ Kafka publish failure does not break move

### Integration Tests (`tests/integration_tests.rs`)
- **Full gRPC flow** testing
- **Real dependencies** (testnet/containers)
- **Performance testing** under load
- **Error handling** and recovery

## 🔧 Configuration

### Environment Variables
```bash
STARKNET_RPC_URL=http://localhost:5050
KAFKA_BOOTSTRAP_SERVERS=localhost:9092
DATABASE_URL=postgres://user:pass@localhost/db
LOG_LEVEL=info
```

### Service Dependencies
- **Starknet Node** - For blockchain interactions
- **Kafka Cluster** - For event streaming
- **PostgreSQL** - For data persistence
- **Redis** - For caching (future)

## 🚀 Deployment

### Docker Compose
```yaml
services:
  core-service:
    build: ./services/core-service
    ports:
      - "50051:50051"
    environment:
      - STARKNET_RPC_URL=${STARKNET_RPC_URL}
      - KAFKA_BOOTSTRAP_SERVERS=${KAFKA_BOOTSTRAP_SERVERS}
      - DATABASE_URL=${DATABASE_URL}
```

### Health Checks
- **gRPC health check** on port 50051
- **Starknet connectivity** check
- **Kafka connectivity** check
- **Database connectivity** check

## 📊 Monitoring & Observability

### Metrics
- **Move processing latency**
- **NFT mint success rate**
- **Kafka message throughput**
- **Database query performance**

### Logging
- **Structured logging** with tracing
- **Request/response correlation**
- **Error tracking** with context

### Alerting
- **Service health** monitoring
- **Performance degradation** alerts
- **Error rate** thresholds

## 🔮 Future Enhancements

### Planned Features
- **Caching layer** for frequently accessed data
- **Circuit breaker** for external dependencies
- **Rate limiting** for API endpoints
- **A/B testing** framework for game mechanics

### Scalability Improvements
- **Horizontal scaling** of GameEngine instances
- **Database sharding** for high-volume data
- **Event sourcing** for audit trails
- **Microservice decomposition** for specific domains

## 🛠️ Development Workflow

### Local Development
```bash
# Start dependencies
docker-compose up -d

# Run tests
cargo test

# Start service
cargo run --bin core-service
```

### Code Quality
- **Rust clippy** for linting
- **cargo fmt** for formatting
- **Unit test coverage** > 80%
- **Integration test coverage** for critical paths

## 📚 API Documentation

### gRPC Endpoints
```protobuf
service CoreService {
  rpc MovePlayer(MovePlayerRequest) returns (MovePlayerResponse);
  // Future endpoints for PvP, rewards, etc.
}
```

### Request/Response Examples
```json
// MovePlayerRequest
{
  "user_id": "player123",
  "direction": "up"
}

// MovePlayerResponse
{
  "success": true,
  "message": "Move processed. Ink: 10, NFT: true, Streak: true"
}
```

---

This architecture provides a solid foundation for the StreetCred Clash game, with clear separation of concerns, comprehensive testing, and room for future growth. 