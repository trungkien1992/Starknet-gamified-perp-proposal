# 🎮 StreetCred Clash - Game Testing Guide

## 🚀 Quick Start

The Flutter app is currently running at: **http://localhost:3000**

## 🎯 What You Can Test

### **1. Trade Arena - Swipe Gestures & Haptic Feedback**
- **Location**: Main screen (Trade Arena)
- **Features to Test**:
  - ✨ **Velocity-based swipe gestures** - Swipe up/down with different speeds
  - 🎆 **Progressive haptic feedback** - Feel the vibration intensity change
  - 🌈 **Real-time visual effects** - Watch spray trails, confetti, sparkles
  - ⚡ **Leverage calculation** - See percentage change with swipe distance
  - 🎵 **Celebration animations** - Complete swipes trigger particle effects

**How to Test**:
1. Click/touch in the dark spray area
2. Drag up (LONG) or down (SHORT) with varying speeds
3. Watch for:
   - Spray color changes (green for LONG, red for SHORT)
   - Velocity indicators for fast swipes
   - Confetti burst on release
   - Haptic feedback (if on mobile/supported browser)

### **2. Drip NFT Inventory - Reward Animations**
- **Location**: Navigate to Profile screen → "My Drip" section
- **Features to Test**:
  - ✨ **Rarity-specific effects** - Different animations for common/rare/epic/legendary
  - 🎉 **Equip celebrations** - Tap NFTs to equip with sparkle effects
  - 💎 **Legendary sparkles** - Special effects for legendary items
  - 🔄 **Smooth transitions** - Equipment status changes with animation

**How to Test**:
1. Go to Profile screen (if available in navigation)
2. Tap different NFT items to equip them
3. Watch for:
   - Scale animations on tap
   - Sparkle effects for legendary items
   - Border color changes
   - "EQUIPPED" status animations

### **3. Real-time Event System** 
- **Location**: Overlay on all screens
- **Features to Test**:
  - 🌐 **WebSocket connectivity** - Real-time event streaming
  - 🎊 **Event animations** - XP bursts, streak notifications
  - 📡 **Live updates** - Backend events trigger frontend animations

**How to Test**:
1. Use the dev buttons in the game (if visible)
2. Or manually trigger events via API:
   ```bash
   curl -X POST "http://localhost:8080/test/emit-event?event_type=xp.earned&player_id=test"
   ```

### **4. State Management - Riverpod Integration**
- **Location**: Throughout the app
- **Features to Test**:
  - 💾 **Persistent state** - Ink balance, XP, equipped items
  - 🔄 **Real-time updates** - State changes reflect immediately
  - 🏗️ **Error handling** - Graceful handling of edge cases

## 🧪 Manual Testing Checklist

### **Visual & Animation Tests**
- [ ] Swipe gestures work smoothly in Trade Arena
- [ ] Spray colors change based on direction (up=green, down=red)
- [ ] Velocity indicators appear for fast swipes
- [ ] Confetti animations trigger on swipe completion
- [ ] NFT inventory shows rarity-based glowing effects
- [ ] Equipment animations play when tapping NFTs
- [ ] Text scales and color changes during interactions

### **Interaction Tests**
- [ ] Tap/click responsiveness is immediate
- [ ] Haptic feedback works (on supported devices)
- [ ] State persists between screen changes
- [ ] No crashes or freezing during normal use
- [ ] Smooth transitions between animations

### **Real-time Features**
- [ ] WebSocket connection establishes automatically
- [ ] Test events trigger UI responses
- [ ] Event overlays appear and disappear correctly
- [ ] No memory leaks during extended use

## 🔧 Backend Testing (Optional)

If you want to test the full stack:

### **1. Start Backend Services**
```bash
# Terminal 1 - Start API Gateway
cd services/api-gateway
python -m uvicorn src.main:app --reload --port 8080

# Terminal 2 - Start Core Service  
cd services/core-service
cargo run

# Terminal 3 - Start Redis (if needed)
redis-server
```

### **2. Test WebSocket Events**
```bash
# Emit test XP event
curl -X POST "http://localhost:8080/test/emit-event?event_type=xp.earned&player_id=test-player"

# Emit streak milestone
curl -X POST "http://localhost:8080/test/emit-event?event_type=streak.milestone&player_id=test-player"

# Emit NFT reward
curl -X POST "http://localhost:8080/test/emit-event?event_type=drip.minted&player_id=test-player"
```

### **3. Check API Health**
```bash
# Health check
curl http://localhost:8080/healthz

# WebSocket info
curl http://localhost:8080/test/emit-event
```

## 🐛 Known Issues & Workarounds

1. **Audio not working**: Sound files are placeholder - visual feedback still works
2. **Some warnings in console**: These are development warnings and don't affect functionality  
3. **WebSocket auto-reconnect**: Connection may take a few seconds to establish

## 🎨 Visual Features to Notice

### **Street Art Theme**
- Neon color palette (pink, blue, yellow, green)
- Graffiti-style typography
- Dark alley background gradients
- Street art inspired animations

### **Dopamine-Driven Feedback**
- Immediate visual responses to all interactions
- Progressive animation intensity based on action
- Celebration patterns that scale with reward value
- Native mobile interaction patterns

## 🚀 Performance Notes

The app is optimized for:
- **60 FPS animations** on modern devices
- **Minimal state management overhead** with Riverpod
- **Efficient rendering** with Flutter's optimized engine
- **Real-time responsiveness** for game-like feel

---

**🎉 Enjoy testing the game! The goal is to create a "Feel like Snapchat, Function like a DeFi engine" experience.**