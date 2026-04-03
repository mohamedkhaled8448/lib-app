// lib/services/favorite_service.dart
//
// This service centralises all favorite logic so that switching from local
// state to a real API later only requires editing this one file.
//
// Current implementation: operates on a local Set<String> passed by reference.
// Future API implementation: replace the body of addFavorite / removeFavorite
// with ApiService.addFavorite(userId, bookId) / ApiService.removeFavorite(...).

class FavoriteService {
  /// Adds [bookId] to the local [favoriteIds] set.
  ///
  /// Future API hook:
  ///   await ApiService.addFavorite(userId, bookId);
  static Future<void> addFavorite({
    required String bookId,
    required Set<String> favoriteIds,
    // Future: required String userId,
  }) async {
    // ── Future API call goes here ──────────────────────────────────────────
    // await ApiService.addFavorite(userId, bookId);
    // ──────────────────────────────────────────────────────────────────────

    // Local state update (remove this once API is wired up)
    favoriteIds.add(bookId);
  }

  /// Removes [bookId] from the local [favoriteIds] set.
  ///
  /// Future API hook:
  ///   await ApiService.removeFavorite(userId, bookId);
  static Future<void> removeFavorite({
    required String bookId,
    required Set<String> favoriteIds,
    // Future: required String userId,
  }) async {
    // ── Future API call goes here ──────────────────────────────────────────
    // await ApiService.removeFavorite(userId, bookId);
    // ──────────────────────────────────────────────────────────────────────

    // Local state update (remove this once API is wired up)
    favoriteIds.remove(bookId);
  }
}
