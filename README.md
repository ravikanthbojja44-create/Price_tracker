# price_tracker

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase Setup

The app currently runs in frontend demo mode using in-memory sample products
and user actions. Tracked products and wishlist changes reset when the app
restarts. Firestore repositories, security rules, and the Cloud Function are
retained for later integration; Firebase project configuration is not needed
to run this demo frontend.

### Console Setup

1. Create or select a Firebase project.
2. Register an Android app with application ID `com.example.price_tracker`.
	 If you change `applicationId` in `android/app/build.gradle.kts`, register
	 that exact ID instead.
3. In **Authentication > Sign-in method**, enable **Anonymous**.
4. In **Firestore Database**, create a database in production mode.
5. Cloud Functions deployment requires the Firebase project to use the Blaze
	 billing plan. Review expected usage and billing before enabling it.

### Local Setup

Install and authenticate the Firebase CLI, then activate FlutterFire:

```powershell
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
```

From the project root, select the actual Firebase project and generate the
platform options file. Do not create `lib/firebase_options.dart` manually.

```powershell
firebase use --add
flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID --platforms=android
flutter pub get
```

On Windows, enable Developer Mode if Flutter reports that plugin symlinks are
not available (`start ms-settings:developers`), then rerun `flutter pub get`.

Install and compile the trusted backend:

```powershell
Set-Location functions
npm install
npm run build
Set-Location ..
```

Deploy the Firestore rules and Cloud Function from the project root:

```powershell
firebase deploy --only firestore:rules,functions
```

The `firestore.rules` file denies client writes to the catalog, price history,
and alerts. Add catalog documents through the Firebase Console or a trusted
Admin SDK importer. App clients can only read catalog data and modify their own
tracking and wishlist documents.

### Firestore Schema

- `products/{productId}`: `name`, `category`, `price`, `oldPrice`, `store`,
	and `image`.
- `products/{productId}/priceHistory/{entryId}`: `price`, `store`, and
	`recordedAt`; written by the deployed Cloud Function when a product is added
	or its price changes.
- `users/{uid}/trackedProducts/{productId}`: `productId`, `targetPrice`, and
	server timestamps.
- `users/{uid}/wishlist/{productId}`: `productId` and `addedAt`.
- `users/{uid}/alerts/{alertId}`: product and before/after prices; written by
	the Cloud Function when a decreased price reaches a user's target.

The Cloud Function processes catalog changes supplied by a trusted importer or
operator. It does not monitor retailers or fetch prices. Real retailer tracking
requires a permitted retailer API or price-data provider and a separate
scheduled backend process.
