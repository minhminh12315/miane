import 'package:in_app_purchase/in_app_purchase.dart';

/// Thin wrapper around the `in_app_purchase` plugin for the MIANE Pro
/// subscription. In Simulator/dev, this talks to the StoreKit Testing
/// sandbox configured at ios/Runner/Products.storekit (only active when the
/// app is launched via Xcode, not `flutter run`/`simctl launch`).
class IapService {
  /// Must match the productID in ios/Runner/Products.storekit and the
  /// App Store Connect / Play Console product configured for production.
  static const String proMonthlyProductId = 'com.example.mobile.pro.monthly';

  final InAppPurchase _iap = InAppPurchase.instance;

  Future<bool> isAvailable() => _iap.isAvailable();

  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  Future<ProductDetails?> getProProduct() async {
    final response =
        await _iap.queryProductDetails({proMonthlyProductId});
    if (response.error != null || response.productDetails.isEmpty) {
      return null;
    }
    return response.productDetails.first;
  }

  Future<void> buyPro(ProductDetails product) {
    final purchaseParam = PurchaseParam(productDetails: product);
    // Auto-renewable subscriptions go through the same buyNonConsumable
    // entry point as one-time non-consumables in this plugin's API.
    return _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> completePurchase(PurchaseDetails purchase) {
    return _iap.completePurchase(purchase);
  }
}
