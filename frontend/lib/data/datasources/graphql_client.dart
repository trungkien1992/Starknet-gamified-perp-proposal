// File: frontend/lib/data/datasources/graphql_client.dart
//
// Configures and provides our shared GraphQL client.

import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

// 1. Define the API endpoints in a central place.
const String _devApiUrl = 'http://localhost:8000/graphql';
const String _prodApiUrl = 'https://api.streetcredclash.com/graphql'; // Example

// 2. The URL is chosen based on the build environment.
final HttpLink httpLink = HttpLink(
  // Use the development URL for debug builds, and the production URL for release builds.
  kDebugMode ? _devApiUrl : _prodApiUrl,
);

// 3. The GraphQLClient is created using this link.
// This client will be injected into our repositories.
final GraphQLClient client = GraphQLClient(
  link: httpLink,
  cache: GraphQLCache(store: InMemoryStore()),
);
