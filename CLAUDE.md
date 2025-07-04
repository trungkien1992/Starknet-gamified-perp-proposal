# claude.md

> This app was entirely built using Claude-generated code and guidance.

## 🕹️ Overview

**StreetCred Clash** is a mobile-first gamified perpetual trading prototype for the [StarkWare Perps Bounty](https://www.starknet.io). It's a Swift, haptic, dopamine-driven rethinking of how Gen-Z trades — not with charts, but with streaks, XP bursts, drips, and swipe fights.

This v0 was built in Flutter (for mobile UX), Rust (for game logic), Cairo (for smart contracts), and modern backend infra using Kafka + Postgres. All core functionality — from XP animations to backend PvP resolution — was shaped by prompts, tests, and architecture written by Claude.

---

## 🛠️ Project Goals

* **Feel like Snapchat. Function like a DeFi engine.**
* Replace dashboards and charts with *feelings*: XP bursts, loot, loss recovery.
* Deliver dopamine per tap, streaks per session, and flex NFTs per trade.
* Showcase Extended's API + Starknet + Cairo-based smart contracts in a playful, viral context.

---

## 🧱 Architecture

| Layer      | Description                                                      |
| ---------- | ---------------------------------------------------------------- |
| Flutter UI | Modular feature folders (`xp`, `drip`, `streak`, `pvp`, etc.)    |
| Rust Core  | PvP resolution engine, XP/streak/trade logic, event dispatcher   |
| Kafka      | Real-time game events streamed from backend to frontend          |
| WebSocket  | Frontend listens for XP/streak/loot to animate state updates     |
| Cairo      | Drip NFTs, badge mints, paymaster integration for gasless trades |
| Postgres   | Stores PvP sessions, trade history, streaks, NFT inventory       |

---

## 💡 Design Philosophy

Claude's instructions helped us implement these principles:

* **Use Flutter idioms**: `ProviderScope`, `StateNotifier`, clear `features/` boundaries
* **Single-action core loop**: Swipe to play, feel the result instantly
* **Front-to-back modularity**: Every feature (XP, PvP, Drip) has a Rust module, Dart state, and protocol buffer message
* **Mock mode toggle**: Devs can test without hitting real endpoints
* **Strict CI discipline**: Docker-first, Mac-compatible testing via `test_local.sh`

---

## 🔧 Claude-Powered Features

| Feature                    | Claude's Contribution                                               |
| -------------------------- | ------------------------------------------------------------------- |
| PvP battle resolution      | Wrote `pvp.rs`, reward emit logic, rollback safety                  |
| GameEvent system           | Architected dispatcher trait, JSON serialization, WS + Kafka bridge |
| XP / streak logic          | Designed trait structure + frontend feedback hooks                  |
| Drip NFT animation         | Created lootbox spec, UI structure, rarity visual rules             |
| BeReal-style streak prompt | Modeled prompt frequency, pulse animation, and test harness         |
| CI / Testing infra         | Refactored all test scripts for Docker compatibility                |

---

## 📈 Tech Stack

* **Frontend**: Flutter + Dart + Riverpod + Starknet.dart
* **Backend**: Rust (Axum, Tokio, SQLx, Kafka)
* **Smart Contracts**: Cairo 1.x, deployed on Starknet
* **Infra**: Postgres, Redis, Docker Compose, GitHub Actions

---

## 📦 What's Done in v0

* Swipe-based trading arena with mock/real mode
* XP pulse animation + GameEvent listener wired
* PvP match resolution emits XP and badge events
* Drip inventory with rarity glow (visual NFT flex layer)
* Full test flow in Docker, CI integrated

---

## 🧱 What Claude Said to Ship Later

* Plugin system for modded cities and NFT packs
* Social memes on win/loss (share modal)
* Squad mode (alliances + challenge battles)
* Deep NFA tips for bad traders (mentor AI)
* Leaderboard NFT staking / bet-on-friend mode

---

## 🤝 Team

This was built by a small, focused team:

* One full-stack engineer (Rust/Cairo/Flutter)
* One prompt engineer (Claude + ChatGPT)
* One tester / deployment ops

---

## 🚀 Claude's Verdict (if Claude had one)

> "The code is clear. The dopamine is real. The PvP emits. The modal pulses. You built a real game. Now give it a million players."