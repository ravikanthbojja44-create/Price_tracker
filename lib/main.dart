import 'package:flutter/material.dart';

import 'models/product.dart';
import 'services/data_sources.dart';
import 'services/demo_data_repository.dart';
import 'widgets/tracked_product_card.dart';

void main() {
  runApp(const PriceTrackerApp());
}

class PriceTrackerApp extends StatefulWidget {
  const PriceTrackerApp({super.key});

  @override
  State<PriceTrackerApp> createState() => _PriceTrackerAppState();
}

class _PriceTrackerAppState extends State<PriceTrackerApp> {
  bool darkMode = false;
  late final ProductRepository _productRepository = DemoProductRepository();
  late final UserDataRepository _userDataRepository = DemoUserDataRepository();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Price Tracker & Drop Alert',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: darkMode ? Brightness.dark : Brightness.light,
      ),
      home: MainScreen(
        darkMode: darkMode,
        productRepository: _productRepository,
        userDataRepository: _userDataRepository,
        onThemeChanged: (value) {
          setState(() {
            darkMode = value;
          });
        },
      ),
    );
  }
}

typedef ProductDataViewBuilder = Widget Function(
  BuildContext context,
  List<Product> products,
  Map<String, TrackedProduct> trackedProducts,
  Set<String> wishlistProductIds,
);

class ProductDataView extends StatefulWidget {
  const ProductDataView({
    super.key,
    required this.productRepository,
    required this.userDataRepository,
    required this.builder,
  });

  final ProductRepository productRepository;
  final UserDataRepository userDataRepository;
  final ProductDataViewBuilder builder;

  @override
  State<ProductDataView> createState() => _ProductDataViewState();
}

class _ProductDataViewState extends State<ProductDataView> {
  late final productStream = widget.productRepository.watchProducts();
  late final trackedStream = widget.userDataRepository.watchTrackedProducts();
  late final wishlistStream = widget.userDataRepository
      .watchWishlistProductIds();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: productStream,
      builder: (context, productSnapshot) {
        if (productSnapshot.hasError) {
          return _dataError('products');
        }
        if (!productSnapshot.hasData) return _dataLoading();
        return StreamBuilder<List<TrackedProduct>>(
          stream: trackedStream,
          builder: (context, trackedSnapshot) {
            if (trackedSnapshot.hasError) {
              return _dataError('tracked products');
            }
            if (!trackedSnapshot.hasData) return _dataLoading();
            return StreamBuilder<List<String>>(
              stream: wishlistStream,
              builder: (context, wishlistSnapshot) {
                if (wishlistSnapshot.hasError) {
                  return _dataError('wishlist');
                }
                if (!wishlistSnapshot.hasData) return _dataLoading();
                return widget.builder(context, productSnapshot.data!, {
                  for (final tracked in trackedSnapshot.data!)
                    tracked.productId: tracked,
                }, wishlistSnapshot.data!.toSet());
              },
            );
          },
        );
      },
    );
  }
}

Widget _dataLoading() => const Center(child: CircularProgressIndicator());

Widget _dataError(String dataName) => Center(
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: Text('Unable to load $dataName.'),
  ),
);

Future<double?> _requestTargetPrice(
  BuildContext context,
  double suggestedPrice,
) async {
  return showDialog<double>(
    context: context,
    builder: (context) => _TargetPriceDialog(suggestedPrice: suggestedPrice),
  );
}

class _TargetPriceDialog extends StatefulWidget {
  const _TargetPriceDialog({required this.suggestedPrice});

  final double suggestedPrice;

  @override
  State<_TargetPriceDialog> createState() => _TargetPriceDialogState();
}

class _TargetPriceDialogState extends State<_TargetPriceDialog> {
  late final TextEditingController controller = TextEditingController(
    text: widget.suggestedPrice.toStringAsFixed(0),
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set target price'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Target price',
          prefixText: '₹',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value = double.tryParse(controller.text.trim());
            if (value != null && value > 0) Navigator.pop(context, value);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
// MAIN SCREEN
// ------------------------------------------------------------

class MainScreen extends StatefulWidget {
  final bool darkMode;
  final ProductRepository productRepository;
  final UserDataRepository userDataRepository;
  final Function(bool) onThemeChanged;

  const MainScreen({
    super.key,
    required this.darkMode,
    required this.productRepository,
    required this.userDataRepository,
    required this.onThemeChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  Widget getPage() {
    switch (selectedIndex) {
      case 0:
        return HomePage(
          productRepository: widget.productRepository,
          userDataRepository: widget.userDataRepository,
          onNavigate: (index) {
            setState(() {
              selectedIndex = index;
            });
          },
        );

      case 1:
        return ProductsPage(
          productRepository: widget.productRepository,
          userDataRepository: widget.userDataRepository,
        );

      case 2:
        return TrackerPage(
          productRepository: widget.productRepository,
          userDataRepository: widget.userDataRepository,
        );

      case 3:
        return AlertsPage(userDataRepository: widget.userDataRepository);

      case 4:
        return WishlistPage(
          productRepository: widget.productRepository,
          userDataRepository: widget.userDataRepository,
        );

      case 5:
        return ServicesPage();

      case 6:
        return AboutPage();

      case 7:
        return SettingsPage(
          darkMode: widget.darkMode,
          onThemeChanged: widget.onThemeChanged,
        );

      default:
        return HomePage(
          productRepository: widget.productRepository,
          userDataRepository: widget.userDataRepository,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Price Tracker & Drop Alert',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              setState(() {
                selectedIndex = 3;
              });
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Row(
                children: [
                  const Icon(Icons.price_check, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Price Tracker',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const Text('Track. Compare. Save.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            drawerItem(Icons.home, 'Home', 0),
            drawerItem(Icons.shopping_bag, 'Products', 1),
            drawerItem(Icons.track_changes, 'Price Tracker', 2),
            drawerItem(Icons.notifications, 'Drop Alerts', 3),
            drawerItem(Icons.favorite, 'Wishlist', 4),
            drawerItem(Icons.build, 'Services', 5),
            drawerItem(Icons.info, 'About', 6),
            drawerItem(Icons.settings, 'Settings', 7),
          ],
        ),
      ),
      body: getPage(),
    );
  }

  Widget drawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: selectedIndex == index,
      onTap: () {
        Navigator.pop(context);
        setState(() {
          selectedIndex = index;
        });
      },
    );
  }
}

// ------------------------------------------------------------
// HOME PAGE
// ------------------------------------------------------------

class HomePage extends StatelessWidget {
  final Function(int)? onNavigate;
  final ProductRepository productRepository;
  final UserDataRepository userDataRepository;

  const HomePage({
    super.key,
    this.onNavigate,
    required this.productRepository,
    required this.userDataRepository,
  });

  @override
  Widget build(BuildContext context) {
    return ProductDataView(
      productRepository: productRepository,
      userDataRepository: userDataRepository,
      builder: (context, products, trackedProducts, wishlistProductIds) {
        final deals = products
            .where((product) => product.priceDropped)
            .toList();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Never Miss a Price Drop!',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Track your favourite products and get notified when prices fall.',
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => onNavigate?.call(1),
                      icon: const Icon(Icons.search),
                      label: const Text('Explore Products'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.headlineSmall,
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  quickCard(
                    context,
                    Icons.track_changes,
                    'Track Prices',
                    () => onNavigate?.call(2),
                  ),
                  const SizedBox(width: 15),
                  quickCard(
                    context,
                    Icons.notifications,
                    'View Alerts',
                    () => onNavigate?.call(3),
                  ),
                  const SizedBox(width: 15),
                  quickCard(
                    context,
                    Icons.favorite,
                    'Wishlist',
                    () => onNavigate?.call(4),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              Text(
                'Latest Price Drops',
                style: Theme.of(context).textTheme.headlineSmall,
              ),

              const SizedBox(height: 15),

              if (deals.isEmpty)
                const Text('No price drops available right now.')
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: MediaQuery.sizeOf(context).width < 600
                        ? 600
                        : 300,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: deals.length,
                  itemBuilder: (context, index) {
                    final product = deals[index];
                    final tracked = trackedProducts[product.id];
                    return ProductCard(
                      product: product,
                      userDataRepository: userDataRepository,
                      tracked: tracked != null,
                      wishlisted: wishlistProductIds.contains(product.id),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget quickCard(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback action,
  ) {
    return Expanded(
      child: Card(
        child: InkWell(
          onTap: action,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(icon, size: 35),
                const SizedBox(height: 10),
                Text(title),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// PRODUCTS PAGE
// ------------------------------------------------------------

class ProductsPage extends StatefulWidget {
  final ProductRepository productRepository;
  final UserDataRepository userDataRepository;

  const ProductsPage({
    super.key,
    required this.productRepository,
    required this.userDataRepository,
  });

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  String search = '';
  String category = 'All';

  @override
  Widget build(BuildContext context) {
    return ProductDataView(
      productRepository: widget.productRepository,
      userDataRepository: widget.userDataRepository,
      builder: (context, products, trackedProducts, wishlistProductIds) {
        final filtered = products.where((product) {
          final searchMatch = product.name.toLowerCase().contains(
            search.toLowerCase(),
          );
          final categoryMatch =
              category == 'All' || product.category == category;
          return searchMatch && categoryMatch;
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Products',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) => setState(() => search = value),
                    ),
                  ),
                  const SizedBox(width: 15),
                  DropdownButton<String>(
                    value: category,
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All')),
                      DropdownMenuItem(
                        value: 'Electronics',
                        child: Text('Electronics'),
                      ),
                      DropdownMenuItem(
                        value: 'Fashion',
                        child: Text('Fashion'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => category = value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          products.isEmpty
                              ? 'No products available yet.'
                              : 'No products match your search.',
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent:
                              MediaQuery.sizeOf(context).width < 600
                              ? 600
                              : 300,
                          childAspectRatio: 0.78,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final product = filtered[index];
                          final tracked = trackedProducts[product.id];
                          return ProductCard(
                            product: product,
                            userDataRepository: widget.userDataRepository,
                            tracked: tracked != null,
                            wishlisted: wishlistProductIds.contains(product.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------
// PRODUCT CARD
// ------------------------------------------------------------

class ProductCard extends StatefulWidget {
  final Product product;
  final UserDataRepository userDataRepository;
  final bool tracked;
  final bool wishlisted;

  const ProductCard({
    super.key,
    required this.product,
    required this.userDataRepository,
    required this.tracked,
    required this.wishlisted,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool busy = false;

  Future<void> toggleTracking() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      if (widget.tracked) {
        await widget.userDataRepository.removeTrackedProduct(widget.product.id);
      } else {
        final targetPrice = await _requestTargetPrice(
          context,
          widget.product.price,
        );
        if (targetPrice != null) {
          await widget.userDataRepository.addTrackedProduct(
            widget.product.id,
            targetPrice: targetPrice,
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update price tracking.')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> toggleWishlist() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      if (widget.wishlisted) {
        await widget.userDataRepository.removeWishlistItem(widget.product.id);
      } else {
        await widget.userDataRepository.addWishlistItem(widget.product.id);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update your wishlist.')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Text(
                  product.image,
                  style: const TextStyle(fontSize: 70),
                ),
              ),
            ),

            Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),

            const SizedBox(height: 5),

            Text(
              product.category,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Text(
                  '₹${product.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '₹${product.oldPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5),

            Text(
              '${product.discount.toStringAsFixed(0)}% OFF',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: busy ? null : toggleTracking,
                    child: Text(widget.tracked ? 'Tracking' : 'Track Price'),
                  ),
                ),
                IconButton(
                  onPressed: busy ? null : toggleWishlist,
                  icon: Icon(
                    widget.wishlisted ? Icons.favorite : Icons.favorite_border,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// TRACKER PAGE
// ------------------------------------------------------------

class TrackerPage extends StatelessWidget {
  final ProductRepository productRepository;
  final UserDataRepository userDataRepository;

  const TrackerPage({
    super.key,
    required this.productRepository,
    required this.userDataRepository,
  });

  @override
  Widget build(BuildContext context) {
    return ProductDataView(
      productRepository: productRepository,
      userDataRepository: userDataRepository,
      builder: (context, products, trackedProducts, wishlistProductIds) {
        final productsById = {
          for (final product in products) product.id: product,
        };
        final tracked = trackedProducts.values
            .where((entry) => productsById.containsKey(entry.productId))
            .toList();
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Price Tracker',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              const Text('Products you are currently tracking.'),
              const SizedBox(height: 20),
              if (tracked.isEmpty)
                const Expanded(
                  child: Center(child: Text('No products are being tracked.')),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: tracked.length,
                    itemBuilder: (context, index) {
                      final entry = tracked[index];
                      final product = productsById[entry.productId]!;
                      return TrackedProductCard(
                        product: product,
                        targetPrice: entry.targetPrice,
                        onEditTarget: () async {
                          final targetPrice = await _requestTargetPrice(
                            context,
                            entry.targetPrice,
                          );
                          if (targetPrice == null) return;
                          await userDataRepository.updateTrackedTargetPrice(
                            entry.productId,
                            targetPrice: targetPrice,
                          );
                        },
                        onRemove: () => userDataRepository.removeTrackedProduct(
                          entry.productId,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------
// ALERTS PAGE
// ------------------------------------------------------------

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key, required this.userDataRepository});

  final UserDataRepository userDataRepository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PriceDropAlert>>(
      stream: userDataRepository.watchAlerts(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _dataError('alerts');
        if (!snapshot.hasData) return _dataLoading();
        final alerts = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Drop Alerts',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              const Text('Recent price drops and target-price alerts.'),
              const SizedBox(height: 20),
              Expanded(
                child: alerts.isEmpty
                    ? const Center(child: Text('No price-drop alerts yet.'))
                    : ListView.builder(
                        itemCount: alerts.length,
                        itemBuilder: (context, index) {
                          final alert = alerts[index];
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.arrow_downward),
                              ),
                              title: Text(
                                '${alert.productName} price dropped!',
                              ),
                              subtitle: Text(
                                '₹${alert.oldPrice.toStringAsFixed(0)} → '
                                '₹${alert.newPrice.toStringAsFixed(0)}',
                              ),
                              trailing: Text(
                                '${alert.discount.toStringAsFixed(0)}% OFF',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------
// WISHLIST PAGE
// ------------------------------------------------------------

class WishlistPage extends StatelessWidget {
  const WishlistPage({
    super.key,
    required this.productRepository,
    required this.userDataRepository,
  });

  final ProductRepository productRepository;
  final UserDataRepository userDataRepository;

  @override
  Widget build(BuildContext context) {
    return ProductDataView(
      productRepository: productRepository,
      userDataRepository: userDataRepository,
      builder: (context, products, trackedProducts, wishlistProductIds) {
        final wishlist = products
            .where((product) => wishlistProductIds.contains(product.id))
            .toList();
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wishlist',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: wishlist.isEmpty
                    ? const Center(child: Text('Your wishlist is empty.'))
                    : ListView.builder(
                        itemCount: wishlist.length,
                        itemBuilder: (context, index) {
                          final product = wishlist[index];
                          return Card(
                            child: ListTile(
                              leading: Text(
                                product.image,
                                style: const TextStyle(fontSize: 35),
                              ),
                              title: Text(product.name),
                              subtitle: Text(
                                '₹${product.price.toStringAsFixed(0)}',
                              ),
                              trailing: IconButton(
                                tooltip: 'Remove from wishlist',
                                icon: const Icon(Icons.delete),
                                onPressed: () => userDataRepository
                                    .removeWishlistItem(product.id),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------
// SERVICES PAGE
// ------------------------------------------------------------

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final services = [
      ['Price Tracking', Icons.track_changes],
      ['Price Drop Alerts', Icons.notifications_active],
      ['Price Comparison', Icons.compare_arrows],
      ['Wishlist', Icons.favorite],
      ['Deal Discovery', Icons.local_offer],
      ['Price History', Icons.show_chart],
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Our Services',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          const Text('Everything you need to shop smarter and save money.'),
          const SizedBox(height: 25),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              childAspectRatio: 1.3,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              return Card(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(services[index][1] as IconData, size: 45),
                    const SizedBox(height: 15),
                    Text(
                      services[index][0] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// ABOUT PAGE
// ------------------------------------------------------------

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              const Icon(Icons.price_check, size: 80),
              const SizedBox(height: 20),

              Text(
                'Price Tracker & Drop Alert',
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              const Text(
                'Price Tracker & Drop Alert is a smart shopping assistant '
                'that helps users monitor product prices and discover '
                'better deals.',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              const Card(
                child: Padding(
                  padding: EdgeInsets.all(25),
                  child: Column(
                    children: [
                      Text(
                        'How It Works',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 15),
                      Text(
                        '1. Search for a product.\n\n'
                        '2. Add it to your tracker.\n\n'
                        '3. Set your target price.\n\n'
                        '4. Monitor price changes.\n\n'
                        '5. Get notified when the price drops.',
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'Track. Compare. Save.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// SETTINGS PAGE
// ------------------------------------------------------------

class SettingsPage extends StatelessWidget {
  final bool darkMode;
  final Function(bool) onThemeChanged;

  const SettingsPage({
    super.key,
    required this.darkMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineMedium),

        const SizedBox(height: 20),

        Card(
          child: SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Change the appearance of the app'),
            secondary: const Icon(Icons.dark_mode),
            value: darkMode,
            onChanged: onThemeChanged,
          ),
        ),

        Card(
          child: SwitchListTile(
            title: const Text('Price Drop Notifications'),
            subtitle: const Text('Receive alerts when tracked prices decrease'),
            secondary: const Icon(Icons.notifications),
            value: true,
            onChanged: (value) {},
          ),
        ),

        Card(
          child: ListTile(
            leading: const Icon(Icons.currency_rupee),
            title: const Text('Currency'),
            subtitle: const Text('Indian Rupee (₹)'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {},
          ),
        ),

        Card(
          child: ListTile(
            leading: const Icon(Icons.info),
            title: const Text('App Version'),
            subtitle: const Text('1.0.0'),
          ),
        ),

        Card(
          child: ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Help & Support'),
                    content: const Text(
                      'For support, please contact:\n'
                      'support@pricetracker.com',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
