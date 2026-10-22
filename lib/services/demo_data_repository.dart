import 'dart:async';

import '../models/product.dart';
import 'data_sources.dart';

class DemoProductRepository implements ProductRepository {
  static final List<Product> _products = List.unmodifiable([
    const Product(
      id: 'wireless-headphones',
      name: 'Wireless Headphones',
      category: 'Electronics',
      price: 2499,
      oldPrice: 3999,
      store: 'Tech Store',
      image: '🎧',
    ),
    const Product(
      id: 'smart-watch',
      name: 'Smart Watch',
      category: 'Electronics',
      price: 3499,
      oldPrice: 4999,
      store: 'Smart Shop',
      image: '⌚',
    ),
    const Product(
      id: 'running-shoes',
      name: 'Running Shoes',
      category: 'Fashion',
      price: 1999,
      oldPrice: 2999,
      store: 'Sports Store',
      image: '👟',
    ),
    const Product(
      id: 'bluetooth-speaker',
      name: 'Bluetooth Speaker',
      category: 'Electronics',
      price: 1599,
      oldPrice: 2499,
      store: 'Audio Hub',
      image: '🔊',
    ),
    const Product(
      id: 'laptop-backpack',
      name: 'Laptop Backpack',
      category: 'Fashion',
      price: 999,
      oldPrice: 1499,
      store: 'Bag World',
      image: '🎒',
    ),
    const Product(
      id: 'mechanical-keyboard',
      name: 'Mechanical Keyboard',
      category: 'Electronics',
      price: 2999,
      oldPrice: 4499,
      store: 'Computer Store',
      image: '⌨️',
    ),
  ]);

  @override
  Stream<List<Product>> watchProducts() => Stream.value(_products);

  @override
  Stream<List<PriceHistoryEntry>> watchPriceHistory(String productId) =>
      Stream.value(const []);
}

class DemoUserDataRepository implements UserDataRepository {
  final Map<String, TrackedProduct> _trackedProducts = {};
  final Set<String> _wishlistProductIds = {};
  final _ReplayValue<List<TrackedProduct>> _trackedProductsValue = _ReplayValue(
    const [],
  );
  final _ReplayValue<List<String>> _wishlistValue = _ReplayValue(const []);

  @override
  Stream<List<TrackedProduct>> watchTrackedProducts() =>
      _trackedProductsValue.stream;

  @override
  Future<void> addTrackedProduct(
    String productId, {
    required double targetPrice,
  }) async {
    final current = _trackedProducts[productId];
    _trackedProducts[productId] = TrackedProduct(
      productId: productId,
      targetPrice: targetPrice,
      createdAt: current?.createdAt ?? DateTime.now(),
    );
    _trackedProductsValue.add(_trackedProducts.values.toList());
  }

  @override
  Future<void> updateTrackedTargetPrice(
    String productId, {
    required double targetPrice,
  }) async {
    final current = _trackedProducts[productId];
    if (current == null) return;
    _trackedProducts[productId] = TrackedProduct(
      productId: productId,
      targetPrice: targetPrice,
      createdAt: current.createdAt,
    );
    _trackedProductsValue.add(_trackedProducts.values.toList());
  }

  @override
  Future<void> removeTrackedProduct(String productId) async {
    _trackedProducts.remove(productId);
    _trackedProductsValue.add(_trackedProducts.values.toList());
  }

  @override
  Stream<List<String>> watchWishlistProductIds() => _wishlistValue.stream;

  @override
  Future<void> addWishlistItem(String productId) async {
    _wishlistProductIds.add(productId);
    _wishlistValue.add(_wishlistProductIds.toList());
  }

  @override
  Future<void> removeWishlistItem(String productId) async {
    _wishlistProductIds.remove(productId);
    _wishlistValue.add(_wishlistProductIds.toList());
  }

  @override
  Stream<List<PriceDropAlert>> watchAlerts() => Stream.value(const []);
}

class _ReplayValue<T> {
  _ReplayValue(this._value);

  T _value;
  final Set<MultiStreamController<T>> _listeners = {};

  Stream<T> get stream => Stream<T>.multi((controller) {
    _listeners.add(controller);
    controller.add(_value);
    controller.onCancel = () => _listeners.remove(controller);
  });

  void add(T value) {
    _value = value;
    for (final listener in List<MultiStreamController<T>>.of(_listeners)) {
      listener.add(value);
    }
  }
}
