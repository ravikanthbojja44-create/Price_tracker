import '../models/product.dart';

abstract interface class ProductRepository {
  Stream<List<Product>> watchProducts();

  Stream<List<PriceHistoryEntry>> watchPriceHistory(String productId);
}

abstract interface class UserDataRepository {
  Stream<List<TrackedProduct>> watchTrackedProducts();

  Future<void> addTrackedProduct(
    String productId, {
    required double targetPrice,
  });

  Future<void> updateTrackedTargetPrice(
    String productId, {
    required double targetPrice,
  });

  Future<void> removeTrackedProduct(String productId);

  Stream<List<String>> watchWishlistProductIds();

  Future<void> addWishlistItem(String productId);

  Future<void> removeWishlistItem(String productId);

  Stream<List<PriceDropAlert>> watchAlerts();
}
