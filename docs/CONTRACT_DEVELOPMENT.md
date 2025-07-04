# Contract Development Guide

## Overview

This guide covers developing Cairo smart contracts for the Starknet gamified perpetual trading platform, with a focus on the SCDrip ERC721 contract.

## 🏗️ Contract Architecture

### SCDrip Contract Structure

```cairo
%lang starknet

from openzeppelin::token::erc721::ERC721 import ERC721
from openzeppelin::access::ownable::Ownable import Ownable

@contract
impl SCDrip of ERC721, Ownable {
    // Core ERC721 functionality with ownership controls
}
```

### Key Components

- **ERC721 Base**: Standard NFT functionality from OpenZeppelin
- **Ownable**: Access control for minting and admin functions
- **Custom Logic**: Game-specific features and metadata handling

## 🔧 Metadata URI Handling

### Current Implementation

The contract currently returns a `felt252` for `token_uri`:

```cairo
fn token_uri(self: @ContractState, token_id: u256) -> felt252 {
    // TODO: Implement real metadata URI logic
    return 0;
}
```

### Recommended Improvements

#### 1. String-based URI Storage

```cairo
use starknet::contract_address::ContractAddress;
use starknet::get_caller_address;

#[storage]
struct Storage {
    // ... existing storage ...
    token_uris: LegacyMap<u256, felt252>,
    base_uri: felt252,
}

#[external(v0)]
impl SCDripImpl of super::SCDrip<ContractState> {
    fn set_token_uri(ref self: ContractState, token_id: u256, uri: felt252) {
        self.assert_only_owner();
        self.token_uris.write(token_id, uri);
    }

    fn set_base_uri(ref self: ContractState, base_uri: felt252) {
        self.assert_only_owner();
        self.base_uri.write(base_uri);
    }

    fn token_uri(self: @ContractState, token_id: u256) -> felt252 {
        let base_uri = self.base_uri.read();
        let specific_uri = self.token_uris.read(token_id);
        
        if specific_uri != 0 {
            return specific_uri;
        }
        
        // Return base_uri + token_id if no specific URI
        return base_uri;
    }
}
```

#### 2. URI Encoding/Decoding

For proper string handling, consider using a dedicated string library:

```cairo
// Example string utilities
fn encode_uri(base: felt252, token_id: u256) -> felt252 {
    // Implement URI encoding logic
    // Convert base + token_id to proper URI format
}

fn decode_uri(uri: felt252) -> (felt252, u256) {
    // Implement URI decoding logic
    // Extract base and token_id from URI
}
```

## ⛽ Gas and Performance Testing

### Gas Measurement Framework

Create a gas testing module:

```cairo
#[cfg(test)]
mod gas_tests {
    use super::*;
    
    #[test]
    fn test_mint_gas_consumption() {
        let mut contract = deploy_contract();
        let recipient: ContractAddress = 0x123.try_into().unwrap();
        
        // Measure gas for single mint
        let start_gas = get_remaining_gas();
        contract.mint(recipient, 1_u256);
        let end_gas = get_remaining_gas();
        
        let gas_used = start_gas - end_gas;
        println!("Gas used for mint: {}", gas_used);
        
        // Assert reasonable gas consumption
        assert(gas_used < 100000, 'Gas consumption too high');
    }
    
    #[test]
    fn test_batch_mint_gas_consumption() {
        let mut contract = deploy_contract();
        let recipient: ContractAddress = 0x123.try_into().unwrap();
        
        // Measure gas for batch mint
        let start_gas = get_remaining_gas();
        for i in 1..=10 {
            contract.mint(recipient, i.into());
        }
        let end_gas = get_remaining_gas();
        
        let gas_used = start_gas - end_gas;
        println!("Gas used for batch mint (10 tokens): {}", gas_used);
        
        // Assert reasonable gas consumption per token
        assert(gas_used / 10 < 50000, 'Average gas per token too high');
    }
}
```

### Gas Optimization Tips

1. **Batch Operations**: Use batch minting to reduce transaction overhead
2. **Storage Optimization**: Minimize storage writes and use efficient data structures
3. **Loop Optimization**: Avoid unnecessary loops in critical paths
4. **Event Optimization**: Limit event emissions to essential data

## 🚨 Error Handling

### Enhanced Error Messages

```cairo
#[derive(Drop, starknet::Store)]
enum ContractError {
    UnauthorizedMint,
    TokenAlreadyExists,
    TokenNotFound,
    InvalidTokenId,
    MetadataError,
}

fn assert_token_exists(self: @ContractState, token_id: u256) {
    let owner = self.owner_of(token_id);
    assert(owner != ContractAddress::default(), 'Token does not exist');
}

fn assert_token_not_exists(self: @ContractState, token_id: u256) {
    let owner = self.owner_of(token_id);
    assert(owner == ContractAddress::default(), 'Token already exists');
}

fn assert_valid_token_id(token_id: u256) {
    assert(token_id != 0_u256, 'Token ID cannot be zero');
    // Add additional validation as needed
}
```

### Detailed Revert Reasons

```cairo
#[test]
#[should_panic(expected: ('Token already exists',))]
fn test_mint_existing_token() {
    let mut contract = deploy_contract();
    let recipient: ContractAddress = 0x123.try_into().unwrap();
    
    // First mint should succeed
    contract.mint(recipient, 1_u256);
    
    // Second mint of same token should fail
    contract.mint(recipient, 1_u256);
}

#[test]
#[should_panic(expected: ('Token ID cannot be zero',))]
fn test_mint_zero_token_id() {
    let mut contract = deploy_contract();
    let recipient: ContractAddress = 0x123.try_into().unwrap();
    
    contract.mint(recipient, 0_u256);
}
```

## 🔄 Version Management

### Version Pinning Strategy

```toml
# Scarb.toml
[package]
name = "scdrip"
version = "0.1.0"
edition = "2024_07"

[dependencies]
# Pin specific versions for stability
openzeppelin = { git = "https://github.com/OpenZeppelin/cairo-contracts.git", tag = "v0.9.0" }

[dev-dependencies]
cairo_test = "2.8.0"

[tool.scarb]
cairo = "2.8.0"

# Add version constraints
[tool.scarb.metadata]
min_cairo_version = "2.8.0"
max_cairo_version = "2.8.x"
```

### Update Process

1. **Test Compatibility**: Always test with new versions in isolation
2. **Gradual Migration**: Update one dependency at a time
3. **Regression Testing**: Run full test suite after updates
4. **Documentation**: Update version matrix in README

## 🧪 Testing Strategy

### Test Categories

#### 1. Unit Tests
```cairo
#[test]
fn test_basic_functionality() {
    // Test individual functions
}

#[test]
fn test_edge_cases() {
    // Test boundary conditions
}
```

#### 2. Integration Tests
```cairo
#[test]
fn test_full_workflow() {
    // Test complete user workflows
}
```

#### 3. Gas Tests
```cairo
#[test]
fn test_gas_optimization() {
    // Measure and optimize gas usage
}
```

### Test Data Management

```cairo
// Test constants
const TEST_NAME: felt252 = 'SCDrip';
const TEST_SYMBOL: felt252 = 'SCDRIP';
const TEST_TOKEN_ID: u256 = 1_u256;
const TEST_RECIPIENT: felt252 = 0x123;

// Test utilities
fn create_test_contract() -> SCDrip {
    let mut constructor_calldata = array![
        TEST_NAME.into(),
        TEST_SYMBOL.into()
    ];
    SCDrip::deploy(@constructor_calldata.span()).unwrap()
}

fn create_test_account() -> ContractAddress {
    TEST_RECIPIENT.try_into().unwrap()
}
```

## 🔒 Security Considerations

### Access Control

```cairo
// Ensure only owner can mint
fn mint(ref self: ContractState, to: ContractAddress, token_id: u256) {
    self.assert_only_owner();
    self.assert_token_not_exists(token_id);
    self.assert_valid_token_id(token_id);
    
    ERC721::mint(self, to, token_id);
}

// Pausable functionality
fn pause(ref self: ContractState) {
    self.assert_only_owner();
    self.paused.write(true);
}

fn unpause(ref self: ContractState) {
    self.assert_only_owner();
    self.paused.write(false);
}
```

### Input Validation

```cairo
fn validate_mint_params(to: ContractAddress, token_id: u256) {
    // Validate recipient address
    assert(to != ContractAddress::default(), 'Invalid recipient address');
    
    // Validate token ID
    assert(token_id != 0_u256, 'Token ID cannot be zero');
    
    // Add additional validation as needed
}
```

## 📊 Performance Monitoring

### Gas Tracking

```cairo
// Add gas tracking to critical functions
fn mint_with_gas_tracking(ref self: ContractState, to: ContractAddress, token_id: u256) {
    let start_gas = get_remaining_gas();
    
    self.mint(to, token_id);
    
    let end_gas = get_remaining_gas();
    let gas_used = start_gas - end_gas;
    
    // Emit gas usage event
    self.emit(GasUsed { operation: 'mint', gas_used });
}
```

### Event Emission

```cairo
#[event]
#[derive(Drop, starknet::Event)]
enum Event {
    GasUsed: GasUsed,
    TokenMinted: TokenMinted,
    MetadataUpdated: MetadataUpdated,
}

#[derive(Drop, starknet::Event)]
struct GasUsed {
    operation: felt252,
    gas_used: u256,
}

#[derive(Drop, starknet::Event)]
struct TokenMinted {
    to: ContractAddress,
    token_id: u256,
    gas_used: u256,
}
```

## 🚀 Deployment Checklist

### Pre-deployment

- [ ] All tests passing
- [ ] Gas optimization complete
- [ ] Security audit passed
- [ ] Documentation updated
- [ ] Version compatibility verified

### Deployment

- [ ] Deploy to testnet first
- [ ] Verify contract functionality
- [ ] Test with real transactions
- [ ] Monitor gas usage
- [ ] Deploy to mainnet

### Post-deployment

- [ ] Verify contract addresses
- [ ] Update frontend configuration
- [ ] Monitor for issues
- [ ] Document deployment details

## 📚 Additional Resources

- [Cairo Book](https://book.cairo-lang.org/)
- [OpenZeppelin Cairo Contracts](https://github.com/OpenZeppelin/cairo-contracts)
- [Starknet Book](https://book.starknet.io/)
- [Scarb Documentation](https://docs.swmansion.com/scarb/) 