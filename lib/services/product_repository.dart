import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';
import 'data_sources.dart';

export 'data_sources.dart';

class FirestoreProductRepository implements ProductRepository {
  FirestoreProductRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<Product>> watchProducts() {
    return _firestore
        .collection('products')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Product.fromFirestore).toList());
  }

  @override
  Stream<List<PriceHistoryEntry>> watchPriceHistory(String productId) {
    return _firestore
        .collection('products')
        .doc(productId)
        .collection('priceHistory')
        .orderBy('recordedAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(PriceHistoryEntry.fromFirestore).toList(),
        );
  }
}
