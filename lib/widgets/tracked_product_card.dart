import 'package:flutter/material.dart';

import '../models/product.dart';

class TrackedProductCard extends StatelessWidget {
  const TrackedProductCard({
    super.key,
    required this.product,
    required this.targetPrice,
    required this.onEditTarget,
    required this.onRemove,
  });

  final Product product;
  final double targetPrice;
  final VoidCallback onEditTarget;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final targetReached = product.price <= targetPrice;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.image, style: const TextStyle(fontSize: 35)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          Text('Current: ₹${product.price.toStringAsFixed(0)}'),
                          Text('Target: ₹${targetPrice.toStringAsFixed(0)}'),
                        ],
                      ),
                      if (targetReached)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Target reached',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Edit target price',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEditTarget,
                ),
                IconButton(
                  tooltip: 'Remove tracked product',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onRemove,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
