# Game Event Schemas

This document describes the structure of each event type emitted by the backend and consumed by the frontend (via Kafka, WebSocket, etc).

---

## Event Schema Template

| Field      | Type                | Description                                 | Required? |
|------------|---------------------|---------------------------------------------|-----------|
| `type`     | `string`            | Event type identifier (e.g., `xp.earned`)   | Yes       |
| `player_id`| `string`            | Player's unique identifier                  | Yes       |
| `timestamp`| `string` (ISO8601)  | Event timestamp (UTC)                       | Yes       |
| `payload`  | `object` (JSON)     | Event-specific data                         | Varies    |
| ...        | ...                 | Additional top-level fields (if any)        | Optional  |

---

## Example Event Types

### 1. XP Earned

```json
{
  "type": "xp.earned",
  "player_id": "0xabc123",
  "timestamp": "2025-07-04T10:12:00Z",
  "payload": {
    "amount": 25,
    "source": "trade"
  }
}
```

| Payload Field | Type     | Description                | Required? |
|---------------|----------|----------------------------|-----------|
| `amount`      | integer  | XP gained                  | Yes       |
| `source`      | string   | Source of XP (e.g., trade) | No        |

---

### 2. Streak Milestone

```json
{
  "type": "streak.milestone",
  "player_id": "0xabc123",
  "timestamp": "2025-07-04T10:12:00Z",
  "payload": {
    "streak": 7,
    "streak_type": "daily"
  }
}
```

| Payload Field | Type     | Description                | Required? |
|---------------|----------|----------------------------|-----------|
| `streak`      | integer  | Current streak count       | Yes       |
| `streak_type` | string   | Type of streak (daily, etc)| Yes       |

---

### 3. Badge Minted

```json
{
  "type": "badge.minted",
  "player_id": "0xabc123",
  "timestamp": "2025-07-04T10:12:00Z",
  "payload": {
    "badge": "Legendary Drip",
    "nft_id": "0xBADGE123"
  }
}
```

| Payload Field | Type     | Description                | Required? |
|---------------|----------|----------------------------|-----------|
| `badge`       | string   | Badge name                 | Yes       |
| `nft_id`      | string   | NFT identifier             | No        |

---

### 4. Tile Captured

```json
{
  "type": "tile.captured",
  "player_id": "0xabc123",
  "timestamp": "2025-07-04T10:12:00Z",
  "payload": {
    "tile_id": 42,
    "position": { "x": 5, "y": 7 }
  }
}
```

| Payload Field | Type     | Description                | Required? |
|---------------|----------|----------------------------|-----------|
| `tile_id`     | integer  | Unique tile identifier     | Yes       |
| `position`    | object   | Tile coordinates           | Yes       |

---

## Adding a New Event

1. Add a new section for the event type.
2. Provide a sample JSON.
3. Document each payload field in a table.

---

**Tip:**  
Keep this document up to date as you add new event types or change payload structures.  
Share it with both backend and frontend teams for smooth integration! 