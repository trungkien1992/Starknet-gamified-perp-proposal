// This is an ABSTRACT interface for our trade data source.
// Our business logic (Use Cases) will depend on this, not on the
// concrete implementation. This allows us to swap the data source
// without changing any business logic.

abstract class TradeRepository {
  /// Executes a move player action.
  /// Throws an exception if the action fails.
  Future<void> movePlayer({required int x, required int y});
}
