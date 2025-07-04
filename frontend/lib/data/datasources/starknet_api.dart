import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Central abstraction for all Starknet JSON-RPC calls.
class StarknetApi {
  static const String _defaultEndpoint =
      'https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_8/R9ppBBhFDUo9CN8zsHvnqFz7IQcRTaJV';

  // Alternative public endpoints to test
  static const List<String> _alternativeEndpoints = [
    'https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_8/R9ppBBhFDUo9CN8zsHvnqFz7IQcRTaJV',
    'https://starknet-sepolia.public.blastapi.io',
    'https://free-rpc.nethermind.io/sepolia-juno',
    'https://alpha4.starknet.io',
    'https://sepolia.starknet.io',
  ];

  final String rpcUrl;
  StarknetApi({this.rpcUrl = _defaultEndpoint});

  /// Generic JSON-RPC POST with logging
  Future<Map<String, dynamic>> postRpc(
    String method, {
    List<dynamic>? params,
  }) async {
    return await _postRpcToEndpoint(rpcUrl, method, params: params);
  }

  /// Test a specific endpoint with a method and parameters
  Future<Map<String, dynamic>> testEndpoint(
    String endpoint,
    String method, {
    List<dynamic>? params,
  }) async {
    return await _postRpcToEndpoint(endpoint, method, params: params);
  }

  /// Test all alternative endpoints with the same method and parameters
  Future<Map<String, Map<String, dynamic>>> testAllEndpoints(
    String method, {
    List<dynamic>? params,
  }) async {
    final results = <String, Map<String, dynamic>>{};

    for (final endpoint in _alternativeEndpoints) {
      try {
        final result = await _postRpcToEndpoint(
          endpoint,
          method,
          params: params,
        );
        results[endpoint] = result;
      } catch (e) {
        results[endpoint] = {'error': e.toString()};
      }
    }

    return results;
  }

  /// Smart block query with multiple parameter format attempts
  Future<Map<String, dynamic>?> getBlockWithFallback({
    String? blockHash,
    int? blockNumber,
    String? blockTag,
  }) async {
    final attempts = <Map<String, dynamic>>[];

    // Add different parameter formats to try
    if (blockHash != null) {
      attempts.addAll([
        {'block_id': blockHash}, // Direct string
        {
          'block_id': {'block_hash': blockHash},
        }, // Object format
        {
          'block_id': {'hash': blockHash},
        }, // Alternative object key
      ]);
    }

    if (blockNumber != null) {
      attempts.addAll([
        {'block_id': blockNumber}, // Direct number
        {'block_id': blockNumber.toString()}, // String number
        {
          'block_id': {'block_number': blockNumber},
        }, // Object format
        {
          'block_id': {'number': blockNumber},
        }, // Alternative object key
      ]);
    }

    if (blockTag != null) {
      attempts.addAll([
        {'block_id': blockTag}, // Direct string
        {
          'block_id': {'tag': blockTag},
        }, // Object format
      ]);
    }

    // Try each parameter format
    for (final params in attempts) {
      try {
        final result = await postRpc(
          'starknet_getBlockWithTxs',
          params: [params],
        );

        // Check if we got a successful response (not an error)
        if (result.containsKey('result') && result['result'] != null) {
          return result;
        }

        // Log the error but continue trying other formats
        if (result.containsKey('error')) {
          print('❌ Failed with params: $params - Error: ${result['error']}');
        }
      } catch (e) {
        print('❌ Exception with params: $params - $e');
      }
    }

    print('❌ All parameter formats failed for getBlockWithTxs');
    return null;
  }

  /// Test basic connectivity and supported methods
  Future<Map<String, dynamic>> testConnectivity() async {
    final results = <String, dynamic>{};

    // Test basic methods that should work
    final basicMethods = [
      'starknet_chainId',
      'starknet_syncing',
      'starknet_getBlockNumber',
    ];

    for (final method in basicMethods) {
      try {
        final result = await postRpc(method);
        results[method] = result;
      } catch (e) {
        results[method] = {'error': e.toString()};
      }
    }

    return results;
  }

  /// Get supported methods by testing common Starknet RPC methods
  Future<Map<String, bool>> getSupportedMethods() async {
    final methods = [
      'starknet_chainId',
      'starknet_syncing',
      'starknet_getBlockNumber',
      'starknet_getBlockWithTxs',
      'starknet_getBlockWithTxHashes',
      'starknet_getBlockWithReceipts',
      'starknet_getBlockTransactionCount',
      'starknet_getTransactionByHash',
      'starknet_getTransactionByBlockIdAndIndex',
      'starknet_getTransactionReceipt',
      'starknet_getClassAt',
      'starknet_getClassHashAt',
      'starknet_getNonce',
      'starknet_getStorageAt',
      'starknet_call',
      'starknet_estimateFee',
      'starknet_simulateTransactions',
    ];

    final supported = <String, bool>{};

    for (final method in methods) {
      try {
        final result = await postRpc(method, params: []);
        // If we get a response (even an error), the method is supported
        supported[method] = true;
      } catch (e) {
        // If we get an exception, the method is not supported
        supported[method] = false;
      }
    }

    return supported;
  }

  Future<Map<String, dynamic>> _postRpcToEndpoint(
    String endpoint,
    String method, {
    List<dynamic>? params,
  }) async {
    final requestBody = {
      'jsonrpc': '2.0',
      'method': method,
      'params': params ?? [],
      'id': 1,
    };

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return responseData;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } on SocketException catch (e) {
      throw Exception('Network error: $e');
    } on FormatException catch (e) {
      throw Exception('Invalid JSON response: $e');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Get the latest block number using starknet_blockNumber
  Future<int> getLatestBlockNumber() async {
    final result = await postRpc('starknet_blockNumber');
    if (result.containsKey('result') && result['result'] != null) {
      return int.parse(result['result'].toString());
    }
    throw Exception('Failed to get latest block number: \\${result['error']}');
  }

  /// Get full block info
  Future<Map<String, dynamic>> getBlockInfo() async {
    final latestBlockNumber = await getLatestBlockNumber();
    final params = [
      {
        'block_id': {'block_number': latestBlockNumber},
      },
    ];
    final result = await postRpc('starknet_getBlockWithTxs', params: params);
    if (result.containsKey('result') && result['result'] != null) {
      return result['result'];
    }
    throw Exception('Failed to get block info: \\${result['error']}');
  }

  /// Example: Read contract (expand as needed)
  Future<Map<String, dynamic>> callContract({
    required String contractAddress,
    required String entryPointSelector,
    List<String> calldata = const [],
    String blockId = 'latest',
  }) async {
    final result = await postRpc(
      'starknet_call',
      params: [
        {
          'contract_address': contractAddress,
          'entry_point_selector': entryPointSelector,
          'calldata': calldata,
        },
        {'block_id': blockId},
      ],
    );
    if (result.containsKey('result') && result['result'] != null) {
      return result['result'];
    }
    throw Exception('Failed to call contract: ${result['error']}');
  }

  /// Get block with transaction hashes using the latest block number
  Future<Map<String, dynamic>> getBlockWithTxHashes() async {
    final latestBlockNumber = await getLatestBlockNumber();
    final params = [
      {
        'block_id': {'block_number': latestBlockNumber},
      },
    ];
    final result = await postRpc(
      'starknet_getBlockWithTxHashes',
      params: params,
    );
    if (result.containsKey('result') && result['result'] != null) {
      return result['result'];
    }
    throw Exception('Failed to get block with tx hashes: \\${result['error']}');
  }
}
