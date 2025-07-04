// The concrete implementation of our TradeRepository using GraphQL.

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:frontend/domain/repositories/trade_repository.dart';

class GraphQLTradeRepositoryImpl implements TradeRepository {
  final GraphQLClient _client;

  GraphQLTradeRepositoryImpl(this._client);

  @override
  Future<void> movePlayer({required int x, required int y}) async {
    const String mutation = '''
      mutation MovePlayer(\$x: Int!, \$y: Int!) {
        movePlayer(x: \$x, y: \$y) {
          success
          message
        }
      }
    ''';

    final result = await _client.mutate(
      MutationOptions(document: gql(mutation), variables: {'x': x, 'y': y}),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }
  }
}
