import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/product.dart';
import 'data_sources.dart';

export 'data_sources.dart';

class FirestoreUserDataRepository implements UserDataRepository {
  FirestoreUserDataRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('A signed-in user is required to access saved data.');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _userCollection =>
      _firestore.collection('users').doc(_uid).collection('trackedProducts');

  CollectionReference<Map<String, dynamic>> get _wishlistCollection =>
      _firestore.collection('users').doc(_uid).collection('wishlist');

  CollectionReference<Map<String, dynamic>> get _alertsCollection =>
      _firestore.collection('users').doc(_uid).collection('alerts');

  @override
  Stream<List<TrackedProduct>> watchTrackedProducts() {
    return _userCollection.snapshots().map(
      (snapshot) => snapshot.docs.map(TrackedProduct.fromFirestore).toList(),
    );
  }

  @override
  Future<void> addTrackedProduct(
    String productId, {
    required double targetPrice,
  }) async {
    final reference = _userCollection.doc(productId);
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      if (existing.exists) {
        transaction.update(reference, {
          'targetPrice': targetPrice,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(
          reference,
          TrackedProduct(
            productId: productId,
            targetPrice: targetPrice,
          ).toFirestore(),
        );
      }
    });
  }

  @override
  Future<void> updateTrackedTargetPrice(
    String productId, {
    required double targetPrice,
  }) {
    return _userCollection.doc(productId).update({
      'targetPrice': targetPrice,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> removeTrackedProduct(String productId) {
    return _userCollection.doc(productId).delete();
  }

  @override
  Stream<List<String>> watchWishlistProductIds() {
    return _wishlistCollection.snapshots().map(
      (snapshot) => snapshot.docs.map((document) => document.id).toList(),
    );
  }

  @override
  Future<void> addWishlistItem(String productId) {
    return _wishlistCollection.doc(productId).set({
      'productId': productId,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> removeWishlistItem(String productId) {
    return _wishlistCollection.doc(productId).delete();
  }

  @override
  Stream<List<PriceDropAlert>> watchAlerts() {
    return _alertsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(PriceDropAlert.fromFirestore).toList(),
        );
  }
}
