# API Reference

## Overview

The StreetCred Clash backend exposes a gRPC API for game interactions. All endpoints are defined in the `proto/core.proto` file and implemented in the core-service.

## Base URL

- **Development**: `http://localhost:50051`
- **Production**: `https://api.streetcredclash.com:443`

## Authentication

Currently, the API uses simple user ID-based authentication. Future versions will implement JWT tokens.

## Core Service

### MovePlayer

Moves a player in the specified direction and processes all associated game logic.

**Endpoint:** `CoreService.MovePlayer`

**Request:**
```protobuf
message MovePlayerRequest {
  string user_id = 1;    // Player's unique identifier
  string direction = 2;  // Movement direction: "up", "down", "left", "right"
}
```

**Response:**
```protobuf
message MovePlayerResponse {
  bool success = 1;      // Whether the move was successful
  string message = 2;    // Human-readable result message
  int32 ink_earned = 3;  // Amount of ink earned from this move
  bool nft_minted = 4;   // Whether an NFT was minted
  bool streak_updated = 5; // Whether the player's streak was updated
}
```

**Example Request:**
```json
{
  "user_id": "player_123",
  "direction": "up"
}
```

**Example Response:**
```json
{
  "success": true,
  "message": "Move processed successfully. Ink: 10, NFT: true, Streak: true",
  "ink_earned": 10,
  "nft_minted": true,
  "streak_updated": true
}
```

**Error Responses:**

| Error Code | Description | Example |
|------------|-------------|---------|
| `INVALID_ARGUMENT` | Invalid direction or user_id | `{"error": "Invalid direction: 'diagonal'"}` |
| `INTERNAL` | Game engine error | `{"error": "Failed to process move"}` |
| `UNAVAILABLE` | Service temporarily unavailable | `{"error": "Service is starting up"}` |

**Usage Examples:**

```bash
# Using grpcurl
grpcurl -plaintext -d '{"user_id": "player_123", "direction": "up"}' \
  localhost:50051 streetcred.core.v1.CoreService/MovePlayer
```

```python
# Using Python gRPC client
import grpc
from core_pb2 import MovePlayerRequest
from core_pb2_grpc import CoreServiceStub

channel = grpc.insecure_channel('localhost:50051')
stub = CoreServiceStub(channel)

request = MovePlayerRequest(
    user_id="player_123",
    direction="up"
)
response = stub.MovePlayer(request)
print(f"Move successful: {response.success}")
```

```javascript
// Using JavaScript gRPC client
const { CoreServiceClient } = require('./core_grpc_web_pb');
const { MovePlayerRequest } = require('./core_pb');

const client = new CoreServiceClient('http://localhost:50051');

const request = new MovePlayerRequest();
request.setUserId('player_123');
request.setDirection('up');

client.movePlayer(request, {}, (err, response) => {
  if (err) {
    console.error('Error:', err);
    return;
  }
  console.log('Success:', response.getSuccess());
  console.log('Message:', response.getMessage());
});
```

## Game Logic Details

### Valid Directions

- `"up"` - Move player upward
- `"down"` - Move player downward  
- `"left"` - Move player leftward
- `"right"` - Move player rightward

### Move Processing Flow

1. **Validation** - Check if the move is valid for the current tile
2. **Position Update** - Update player's position on the game board
3. **Reward Calculation** - Calculate ink rewards (typically 10 ink per move)
4. **NFT Minting** - Attempt to mint a Drip NFT (success rate varies)
5. **Streak Update** - Update player's daily/weekly streak
6. **Event Publishing** - Publish move event to Kafka for real-time updates

### Reward Mechanics

- **Base Ink Reward**: 10 ink per valid move
- **NFT Minting**: ~5% chance per move (configurable)
- **Streak Bonuses**: Additional rewards for consecutive days
- **Tile Bonuses**: Special rewards for certain tile types

## Error Handling

### Common Error Scenarios

1. **Invalid Move**
   ```json
   {
     "success": false,
     "message": "Invalid move: Cannot move to occupied tile",
     "ink_earned": 0,
     "nft_minted": false,
     "streak_updated": false
   }
   ```

2. **Service Unavailable**
   ```json
   {
     "success": false,
     "message": "Service temporarily unavailable",
     "ink_earned": 0,
     "nft_minted": false,
     "streak_updated": false
   }
   ```

3. **Blockchain Error**
   ```json
   {
     "success": false,
     "message": "Failed to mint NFT: Blockchain error",
     "ink_earned": 10,
     "nft_minted": false,
     "streak_updated": true
   }
   ```

### Retry Logic

- **Transient Errors**: Retry with exponential backoff
- **Permanent Errors**: Return error immediately
- **Rate Limiting**: Implement exponential backoff

## Rate Limiting

- **Default Limit**: 100 requests per minute per user
- **Burst Limit**: 10 requests per second per user
- **Headers**: Rate limit info included in response headers

## Monitoring & Metrics

### Available Metrics

- **Request Rate**: Requests per second
- **Error Rate**: Error percentage
- **Latency**: P50, P95, P99 response times
- **Success Rate**: Successful moves percentage

### Health Check Endpoint

```bash
# Health check
curl http://localhost:50051/health
```

Response:
```json
{
  "status": "SERVING",
  "services": {
    "starknet": "UP",
    "kafka": "UP", 
    "database": "UP"
  }
}
```

## SDKs & Libraries

### Official SDKs

- **Python**: `pip install streetcred-clash-sdk`
- **JavaScript**: `npm install @streetcred/clash-sdk`
- **Rust**: Add to `Cargo.toml`:
  ```toml
  [dependencies]
  streetcred-clash = "0.1.0"
  ```

### Community Libraries

- **Go**: `go get github.com/streetcred/clash-go`
- **Java**: Maven dependency available
- **C#**: NuGet package available

## Versioning

API versioning follows semantic versioning:

- **v1**: Current stable version
- **v1.1**: Backward compatible additions
- **v2**: Breaking changes (future)

### Version Header

```bash
# Specify API version
grpcurl -H "X-API-Version: v1" -plaintext \
  -d '{"user_id": "player_123", "direction": "up"}' \
  localhost:50051 streetcred.core.v1.CoreService/MovePlayer
```

## Migration Guide

### From v0.x to v1.0

- **Breaking Changes**:
  - Response format changed from simple string to structured object
  - Error handling standardized
  - Rate limiting introduced

- **Migration Steps**:
  1. Update client libraries to v1.0
  2. Handle new response format
  3. Implement proper error handling
  4. Add rate limiting logic

## Support

- **Documentation**: [docs.streetcredclash.com](https://docs.streetcredclash.com)
- **Discord**: [discord.gg/streetcredclash](https://discord.gg/streetcredclash)
- **Email**: api-support@streetcredclash.com
- **GitHub Issues**: [github.com/streetcred/clash/issues](https://github.com/streetcred/clash/issues) 