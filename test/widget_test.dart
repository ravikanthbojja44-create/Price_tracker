// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:price_tracker/main.dart';
import 'package:price_tracker/models/product.dart';
import 'package:price_tracker/widgets/tracked_product_card.dart';

void main() {
  test('Product model deserializes and serializes Firestore fields', () {
    final product = Product.fromMap('headphones', {
      'name': 'Wireless Headphones',
      'category': 'Electronics',
      'price': 2499,
      'oldPrice': 3999,
      'store': 'Tech Store',
      'image': 'headphones',
    });

    expect(product.id, 'headphones');
    expect(product.price, 2499);
    expect(product.discount, closeTo(37.5, 0.01));
    expect(product.priceDropped, isTrue);
    expect(product.toFirestore(), {
      'name': 'Wireless Headphones',
      'category': 'Electronics',
      'price': 2499,
      'oldPrice': 3999,
      'store': 'Tech Store',
      'image': 'headphones',
    });
  });

  testWidgets('tracked product card fits a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              children: [
                TrackedProductCard(
                  product: Product.fromMap('headphones', {
                    'name': 'Wireless Headphones with Noise Cancellation',
                    'category': 'Electronics',
                    'price': 2499,
                    'oldPrice': 3999,
                    'store': 'Tech Store',
                    'image': '🎧',
                  }),
                  targetPrice: 2200,
                  onEditTarget: () {},
                  onRemove: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Current: ₹2499'), findsOneWidget);
    expect(find.text('Target: ₹2200'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tracking a product shows it in Tracker on mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PriceTrackerApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Products').last);
    await tester.pumpAndSettle();

    final trackButton = find
        .widgetWithText(ElevatedButton, 'Track Price')
        .first;
    await tester.ensureVisible(trackButton);
    await tester.tap(trackButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Price Tracker').last);
    await tester.pumpAndSettle();

    expect(find.text('Wireless Headphones'), findsOneWidget);
    expect(find.text('Current: ₹2499'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
