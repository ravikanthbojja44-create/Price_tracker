import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.oldPrice,
    required this.store,
    required this.image,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final double oldPrice;
  final String store;
  final String image;

  double get discount =>
      oldPrice == 0 ? 0 : ((oldPrice - price) / oldPrice) * 100;

  bool get priceDropped => price < oldPrice;

  factory Product.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Product ${snapshot.id} has no data.');
    }

    return Product.fromMap(snapshot.id, data);
  }

  factory Product.fromMap(String id, Map<String, dynamic> data) {
    return Product(
      id: id,
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      oldPrice: (data['oldPrice'] as num?)?.toDouble() ?? 0,
      store: data['store'] as String? ?? '',
      image: data['image'] as String? ?? '',
    );
  }

  Map<String, Object?> toFirestore() => {
    'name': name,
    'category': category,
    'price': price,
    'oldPrice': oldPrice,
    'store': store,
    'image': image,
  };
}

class TrackedProduct {
  const TrackedProduct({
    required this.productId,
    required this.targetPrice,
    this.createdAt,
  });

  final String productId;
  final double targetPrice;
  final DateTime? createdAt;

  factory TrackedProduct.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    final timestamp = data['createdAt'];
    return TrackedProduct(
      productId: data['productId'] as String? ?? snapshot.id,
      targetPrice: (data['targetPrice'] as num?)?.toDouble() ?? 0,
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }

  Map<String, Object?> toFirestore() => {
    'productId': productId,
    'targetPrice': targetPrice,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

class PriceHistoryEntry {
  const PriceHistoryEntry({
    required this.price,
    required this.store,
    this.recordedAt,
  });

  final double price;
  final String store;
  final DateTime? recordedAt;

  factory PriceHistoryEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    final timestamp = data['recordedAt'];
    return PriceHistoryEntry(
      price: (data['price'] as num?)?.toDouble() ?? 0,
      store: data['store'] as String? ?? '',
      recordedAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}

class PriceDropAlert {
  const PriceDropAlert({
    required this.productId,
    required this.productName,
    required this.oldPrice,
    required this.newPrice,
    this.createdAt,
  });

  final String productId;
  final String productName;
  final double oldPrice;
  final double newPrice;
  final DateTime? createdAt;

  double get discount =>
      oldPrice == 0 ? 0 : ((oldPrice - newPrice) / oldPrice) * 100;

  factory PriceDropAlert.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    final timestamp = data['createdAt'];
    return PriceDropAlert(
      productId: data['productId'] as String? ?? '',
      productName: data['productName'] as String? ?? '',
      oldPrice: (data['oldPrice'] as num?)?.toDouble() ?? 0,
      newPrice: (data['newPrice'] as num?)?.toDouble() ?? 0,
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}
