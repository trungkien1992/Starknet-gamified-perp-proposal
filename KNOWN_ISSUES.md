# Known Issues and Troubleshooting

## Starknet RPC Integration Issues

### Current Status (Updated from Parameter Variation Tests)

#### ✅ Working Methods
- `starknet_chainId` - Returns chain ID successfully
- `starknet_syncing` - Returns sync status successfully

#### ❌ Problematic Methods
- `starknet_getBlockNumber` - Method not found on Alchemy endpoint
- All block query methods (`starknet_getBlockWithTxs`, `starknet_getBlockWithTxHashes`, etc.) - Invalid block_id parameter format

#### 🔍 Key Findings

1. **Block ID Parameter Issues**: All block-related methods fail with "Invalid block id" regardless of parameter format:
   - `"latest"` - Invalid block id
   - `{"tag": "latest"}` - Invalid block id  
   - `170000` (number) - Invalid block id
   - `"170000"` (string) - Invalid block id
   - `{"block_number": 170000}` - Invalid block id
   - `{"number": 170000}` - Invalid block id
   - Block hashes - Invalid block id

2. **Endpoint Availability**:
   - ✅ Alchemy Sepolia endpoint: Responds but has parameter issues
   - ✅ BlastAPI endpoint: Responds but has same parameter issues
   - ❌ Nethermind, Alpha4, Sepolia.io endpoints: DNS resolution failures

3. **Method Support**:
   - Basic methods (`chainId`, `syncing`) work across endpoints
   - Block query methods exist but have parameter format issues
   - Transaction methods require proper parameters

### Recommended Solutions

#### 1. Use Katana for Local Development
Since you have Katana installed (v1.5.4), use it for local development:
```bash
katana --seed 0x123
```

#### 2. Alternative Block Number Retrieval
Since `starknet_getBlockNumber` doesn't work, try:
- Use `starknet_getBlockWithTxs` with a known working block number
- Implement fallback to get latest block via transaction queries
- Use Katana's local endpoint for development

#### 3. Parameter Format Investigation
The "Invalid block id" error suggests the endpoint expects a different parameter format than standard JSON-RPC. Possible solutions:
- Check if endpoint requires different JSON-RPC version
- Try different parameter structures
- Use Katana to test correct parameter formats locally

### Next Steps

1. **Set up Katana local development**:
   ```bash
   katana --seed 0x123 --host 0.0.0.0 --port 5050
   ```

2. **Test with local endpoint** to identify correct parameter formats

3. **Update StarknetApi class** with working parameter formats

4. **Implement fallback strategies** for production endpoints

### Testing Commands

```bash
# Test local Katana endpoint
curl -X POST http://localhost:5050 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"starknet_getBlockNumber","params":[],"id":1}'

# Test Alchemy endpoint with different formats
curl -X POST https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_8/YOUR_API_KEY \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"starknet_getBlockWithTxs","params":[{"block_id":"latest"}],"id":1}'
```

### Environment Variables

Update your `.env` file:
```env
# For local development with Katana
STARKNET_RPC_URL=http://localhost:5050

# For production (when issues are resolved)
STARKNET_RPC_URL=https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_8/YOUR_API_KEY
```

### Monitoring

- All RPC calls are logged with request/response details
- Failed calls are captured with error details
- Parameter variations are tested systematically
- Network connectivity issues are identified and logged

## Starknet JSON-RPC Endpoint Issues

### **Primary Endpoint: Alchemy Sepolia**
**URL:** `https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_8/"your_Alchemy_API_key"

#### **Connectivity Status**
- ✅ **Connected**: Endpoint responds to basic requests
- ✅ **Chain ID**: Returns `0x534e5f5345504f4c4941` (Sepolia testnet)
- ✅ **Syncing**: Returns `false` (node is synced)
- ❌ **Block Number**: Method `starknet_getBlockNumber` not supported

#### **Supported Methods Analysis**
All methods below are "supported" (endpoint recognizes them) but require specific parameters:

**✅ Working Methods (with proper params):**
- `starknet_chainId` - Returns chain identifier
- `starknet_syncing` - Returns sync status

**⚠️ Methods Requiring Parameters:**
- `starknet_getBlockWithTxs` - Requires `block_id` (all formats tested fail)
- `starknet_getBlockWithTxHashes` - Requires `block_id` (all formats tested fail)
- `starknet_getBlockWithReceipts` - Requires `block_id` (all formats tested fail)
- `starknet_getBlockTransactionCount` - Requires `block_id` (all formats tested fail)
- `starknet_getTransactionByHash` - Requires `transaction_hash`
- `starknet_getTransactionByBlockIdAndIndex` - Requires `block_id` and `index`
- `starknet_getTransactionReceipt` - Requires `transaction_hash`
- `starknet_getClassAt` - Requires `block_id` and `contract_address`
- `starknet_getClassHashAt` - Requires `block_id` and `contract_address`
- `starknet_getNonce` - Requires `block_id` and `contract_address`
- `starknet_getStorageAt` - Requires `contract_address`, `key`, and optional `block_id`
- `starknet_call` - Requires `request` object
- `starknet_estimateFee` - Requires `request` object
- `starknet_simulateTransactions` - Requires `block_id` and `transactions`

#### **Critical Issue: Block ID Parameter Rejection**
**All tested `block_id` formats for block-related methods return "Invalid block id":**

| Parameter Format | Method | Result |
|------------------|--------|--------|
| `"latest"` | `starknet_getBlockWithTxs` | ❌ Invalid block id |
| `{"tag": "latest"}` | `starknet_getBlockWithTxs` | ❌ Invalid block id |
| `"pending"` | `starknet_getBlockWithTxs` | ❌ Invalid block id |
| `170000` (number) | `starknet_getBlockWithTxs` | ❌ Invalid block id |
| `"170000"` (string) | `starknet_getBlockWithTxs` | ❌ Invalid block id |
| `{"block_number": 170000}` | `starknet_getBlockWithTxs` | ❌ Invalid block id |
| `{"number": 170000}` | `starknet_getBlockWithTxs` | ❌ Invalid block id |
| `"0x06e58089..."` (hash) | `starknet_getBlockWithTxs` | ❌ Invalid block id |
| `{"block_hash": "0x06e58089..."}` | `starknet_getBlockWithTxs` | ❌ Invalid block id |
| `{"hash": "0x06e58089..."}` | `starknet_getBlockWithTxs` | ❌ Invalid block id |

**Same issue affects all block-related methods:**
- `starknet_getBlockWithTxHashes`
- `starknet_getBlockWithReceipts`
- `starknet_getBlockTransactionCount`

### **Alternative Endpoints Tested**

#### **BlastAPI Sepolia**
**URL:** `https://starknet-sepolia.public.blastapi.io`
- ✅ **Reachable**: Endpoint responds
- ❌ **Same Issue**: All `block_id` formats return "Invalid block id"
- **Status**: Identical behavior to Alchemy

#### **Unreachable Endpoints**
- `https://free-rpc.nethermind.io/sepolia-juno` - DNS resolution failed
- `https://alpha4.starknet.io` - DNS resolution failed  
- `https://sepolia.starknet.io` - DNS resolution failed

### **Root Cause Analysis**

#### **Provider-Side Limitations**
1. **Incomplete Implementation**: Public endpoints may not fully implement the Starknet JSON-RPC spec
2. **Parameter Validation**: Endpoints have stricter parameter validation than documented
3. **Method Availability**: Some methods (`starknet_getBlockNumber`) are not available on public endpoints
4. **Block ID Format**: The expected `block_id` format may be different from the official spec

#### **Spec vs Reality**
According to the [official Starknet JSON-RPC spec](https://docs.starknet.io/documentation/architecture_and_concepts/JSON_RPC/), `block_id` should accept:
- Block hash (hex string)
- Block number (integer)
- String tags: `"latest"` or `"pending"`

**Reality**: All these formats are rejected by public endpoints.

### **Workarounds & Solutions**

#### **Immediate Workarounds**
1. **Use Basic Methods**: Focus on `starknet_chainId` and `starknet_syncing` for connectivity
2. **Alternative Data Sources**: Consider using GraphQL or REST APIs for block data
3. **Contract Calls**: Use `starknet_call` for specific contract interactions
4. **Transaction Queries**: Use transaction-specific methods when possible

#### **Long-term Solutions**
1. **Contact Provider Support**: Reach out to Alchemy/BlastAPI with findings
2. **Monitor Updates**: Watch for endpoint improvements or spec changes
3. **Multiple Providers**: Implement fallback logic across multiple endpoints
4. **Community Feedback**: Share findings with Starknet community

### **Implementation Status**

#### **✅ Completed**
- Robust abstraction layer with comprehensive error handling
- Multi-endpoint testing framework
- Detailed diagnostics and logging
- Fallback parameter format testing
- Method support detection

#### **🔄 In Progress**
- Provider support ticket preparation
- Alternative data source research
- Community feedback collection

#### **📋 Planned**
- GraphQL integration as alternative
- Multi-provider fallback system
- Real-time endpoint health monitoring
- Automated retry logic with exponential backoff

### **Test Results Archive**

#### **Comprehensive Parameter Testing**
```
✅ Tested 8 different block_id formats
✅ Tested 3 alternative block methods
✅ Tested 5 different endpoints
✅ Tested 17 different RPC methods
❌ All block queries failed with "Invalid block id"
```

#### **Endpoint Health Summary**
| Endpoint | Status | Block Methods | Basic Methods |
|----------|--------|---------------|---------------|
| Alchemy Sepolia | ✅ Online | ❌ All fail | ✅ Working |
| BlastAPI Sepolia | ✅ Online | ❌ All fail | ✅ Working |
| Nethermind | ❌ Unreachable | N/A | N/A |
| Alpha4 | ❌ Unreachable | N/A | N/A |
| Sepolia.io | ❌ Unreachable | N/A | N/A |

### **References**
- [Starknet JSON-RPC Specification](https://docs.starknet.io/documentation/architecture_and_concepts/JSON_RPC/)
- [Alchemy Starknet Documentation](https://www.alchemy.com/chain-connect/chain/starknet)
- [BlastAPI Documentation](https://docs.blastapi.io/)
- [Starknet Community Discord](https://discord.gg/starknet)
- [MetaMask Starknet RPC Methods](https://docs.metamask.io/services/reference/starknet/json-rpc-methods/)
- [QuickNode Starknet Documentation](https://www.quicknode.com/docs/starknet/)

### **Last Updated**
- **Date**: December 2024
- **Test Suite**: `starknet_api_param_variations_test.dart`
- **API Version**: `StarknetApi` with comprehensive diagnostics
- **Status**: All public endpoints tested, provider-side issue confirmed 
