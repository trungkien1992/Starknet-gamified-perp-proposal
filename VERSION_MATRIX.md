# Version Matrix

## Overview

This document tracks the versions of all components used in the Starknet gamified perpetual trading platform and provides guidance for updates.

## 🔧 Core Components

| Component | Current Version | Last Updated | Notes |
|-----------|----------------|--------------|-------|
| Cairo | 2.8.0 | 2024-06-28 | Latest stable |
| Scarb | 2.8.0 | 2024-06-28 | Matches Cairo |
| Katana | 1.5.4 | 2024-06-28 | Docker image |
| OpenZeppelin | v0.9.0 | 2024-06-28 | Cairo contracts |
| Flutter | 3.x | 2024-06-28 | Latest stable |

## 📦 Dependencies

### Contract Dependencies

```toml
# contracts/Scarb.toml
[dependencies]
openzeppelin = { git = "https://github.com/OpenZeppelin/cairo-contracts.git", tag = "v0.9.0" }

[dev-dependencies]
cairo_test = "2.8.0"

[tool.scarb]
cairo = "2.8.0"
```

### Frontend Dependencies

```yaml
# frontend/pubspec.yaml
environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.0.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.0
  starknet_flutter: ^0.1.0  # Placeholder for Starknet Flutter SDK
```

### Backend Dependencies

```toml
# services/core-service/Cargo.toml
[dependencies]
tokio = { version = "1.0", features = ["full"] }
axum = "0.7"
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
```

```toml
# services/api-gateway/pyproject.toml
[tool.poetry.dependencies]
python = "^3.9"
fastapi = "^0.104.0"
uvicorn = "^0.24.0"
```

## 🔄 Update Process

### 1. Version Compatibility Matrix

| Cairo | Scarb | OpenZeppelin | Katana | Status |
|-------|-------|--------------|--------|--------|
| 2.8.0 | 2.8.0 | v0.9.0 | 1.5.4 | ✅ Current |
| 2.7.0 | 2.7.0 | v0.8.0 | 1.4.0 | ⚠️ Deprecated |
| 2.6.0 | 2.6.0 | v0.7.0 | 1.3.0 | ❌ Unsupported |

### 2. Update Checklist

#### Pre-Update
- [ ] Check compatibility matrix
- [ ] Review changelog for breaking changes
- [ ] Create backup of current working state
- [ ] Test update in isolated environment

#### During Update
- [ ] Update one component at a time
- [ ] Run full test suite after each update
- [ ] Document any configuration changes
- [ ] Update version matrix

#### Post-Update
- [ ] Verify all functionality works
- [ ] Update documentation
- [ ] Commit changes with clear message
- [ ] Tag release if applicable

### 3. Automated Update Script

```bash
#!/bin/bash
# scripts/update_versions.sh

set -e

echo "🔄 Starting version update process..."

# Backup current versions
cp contracts/Scarb.toml contracts/Scarb.toml.backup
cp frontend/pubspec.yaml frontend/pubspec.yaml.backup

# Update Cairo and Scarb
echo "📦 Updating Cairo and Scarb..."
curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh

# Update OpenZeppelin
echo "🔒 Updating OpenZeppelin..."
cd contracts
# Update the tag in Scarb.toml manually
cd ..

# Update Flutter
echo "📱 Updating Flutter..."
flutter upgrade

# Run tests
echo "🧪 Running tests..."
./scripts/test_local.sh

echo "✅ Version update completed!"
```

## 🚨 Breaking Changes

### Cairo 2.8.0
- **Breaking**: Some trait implementations changed
- **Migration**: Update OpenZeppelin to v0.9.0
- **Impact**: Contract compilation may fail

### OpenZeppelin v0.9.0
- **Breaking**: ERC721 interface changes
- **Migration**: Update contract imports
- **Impact**: Contract functionality changes

### Katana 1.5.4
- **Breaking**: RPC endpoint changes
- **Migration**: Update client configurations
- **Impact**: Frontend connectivity issues

## 📊 Version Health

### Security Status
- ✅ Cairo 2.8.0: No known vulnerabilities
- ✅ OpenZeppelin v0.9.0: Security audited
- ✅ Katana 1.5.4: Latest stable release

### Performance Status
- ✅ Cairo 2.8.0: Optimized for gas efficiency
- ✅ Scarb 2.8.0: Improved build times
- ✅ Flutter 3.x: Enhanced performance

### Compatibility Status
- ✅ All components compatible
- ✅ Cross-platform support
- ✅ Apple Silicon native support

## 🔍 Version Monitoring

### Automated Checks

```yaml
# .github/workflows/version-check.yml
name: Version Check

on:
  schedule:
    - cron: '0 0 * * 1'  # Weekly on Monday

jobs:
  check-versions:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Check Cairo version
        run: |
          curl -s https://api.github.com/repos/starkware-libs/cairo/releases/latest | jq -r '.tag_name'
      
      - name: Check OpenZeppelin version
        run: |
          curl -s https://api.github.com/repos/OpenZeppelin/cairo-contracts/releases/latest | jq -r '.tag_name'
      
      - name: Check Katana version
        run: |
          curl -s https://api.github.com/repos/dojoengine/katana/releases/latest | jq -r '.tag_name'
      
      - name: Create issue if updates available
        uses: actions/github-script@v7
        with:
          script: |
            // Create issue if new versions are available
            // Implementation details...
```

### Manual Checks

```bash
# Check for updates
scarb --version
flutter --version
docker images | grep katana

# Check dependency updates
cd contracts && scarb update
cd ../frontend && flutter pub outdated
```

## 📝 Version History

### 2024-06-28
- **Cairo**: 2.8.0 → 2.8.0 (no change)
- **Scarb**: 2.8.0 → 2.8.0 (no change)
- **OpenZeppelin**: v0.8.0 → v0.9.0
- **Katana**: 1.4.0 → 1.5.4
- **Flutter**: 3.16.0 → 3.19.0

### 2024-06-15
- **Cairo**: 2.7.0 → 2.8.0
- **Scarb**: 2.7.0 → 2.8.0
- **OpenZeppelin**: v0.7.0 → v0.8.0
- **Katana**: 1.3.0 → 1.4.0

## 🔮 Future Roadmap

### Q3 2024
- **Cairo**: 2.9.0 (expected)
- **OpenZeppelin**: v0.10.0 (expected)
- **Katana**: 1.6.0 (expected)

### Q4 2024
- **Cairo**: 3.0.0 (major release)
- **Flutter**: 4.0.0 (expected)
- **Starknet**: Protocol upgrades

## 📚 Resources

- [Cairo Release Notes](https://github.com/starkware-libs/cairo/releases)
- [OpenZeppelin Cairo Releases](https://github.com/OpenZeppelin/cairo-contracts/releases)
- [Katana Releases](https://github.com/dojoengine/katana/releases)
- [Flutter Release Notes](https://docs.flutter.dev/release/release-notes)
- [Scarb Documentation](https://docs.swmansion.com/scarb/)

## 🆘 Support

For version-related issues:
1. Check the compatibility matrix
2. Review breaking changes section
3. Run the update script
4. Create an issue with version details
5. Contact the development team 