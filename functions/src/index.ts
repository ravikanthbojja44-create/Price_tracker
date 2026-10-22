import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';

initializeApp();

const firestore = getFirestore();

export const recordProductPriceChanges = onDocumentWritten(
  'products/{productId}',
  async (event) => {
    const after = event.data?.after;
    if (!after?.exists) return;

    const product = after.data();
    if (!product) return;
    const newPrice = Number(product['price']);
    if (!Number.isFinite(newPrice) || newPrice <= 0) return;

    const before = event.data?.before;
    const beforeProduct = before?.exists ? before.data() : undefined;
    const previousPrice = beforeProduct
      ? Number(beforeProduct['price'])
      : undefined;
    if (previousPrice !== undefined && previousPrice === newPrice) return;

    const productId = event.params['productId'];
    const historyRef = after.ref
      .collection('priceHistory')
      .doc(event.id);
    await historyRef.set({
      price: newPrice,
      store: typeof product['store'] === 'string' ? product['store'] : '',
      recordedAt: FieldValue.serverTimestamp(),
    });

    if (
      previousPrice === undefined ||
      !Number.isFinite(previousPrice) ||
      newPrice >= previousPrice
    ) {
      return;
    }

    const trackedProducts = await firestore
      .collectionGroup('trackedProducts')
      .where('productId', '==', productId)
      .get();

    const writes: Promise<FirebaseFirestore.WriteResult>[] = [];
    for (const trackedProduct of trackedProducts.docs) {
      const targetPrice = Number(trackedProduct.data()['targetPrice']);
      const userRef = trackedProduct.ref.parent.parent;
      if (!userRef || !Number.isFinite(targetPrice) || newPrice > targetPrice) {
        continue;
      }

      const alertId = `${productId}_${event.id}`;
      writes.push(
        userRef.collection('alerts').doc(alertId).set({
          productId,
          productName: typeof product['name'] === 'string' ? product['name'] : '',
          oldPrice: previousPrice,
          newPrice,
          createdAt: FieldValue.serverTimestamp(),
        }),
      );
    }
    await Promise.all(writes);
  },
);