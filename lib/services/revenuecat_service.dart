import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  // TODO: Replace these with your actual RevenueCat Public API Keys from the dashboard
  static const String _appleApiKey = 'appl_api_key_here';
  static const String _googleApiKey = 'goog_api_key_here';

  // The entitlement ID you set up in RevenueCat (e.g. 'pro')
  static const String entitlementId = 'pro';

  static Future<void> init() async {
    if (kIsWeb) return; // RevenueCat does not support Web currently

    await Purchases.setLogLevel(LogLevel.info);

    PurchasesConfiguration? configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(_googleApiKey);
    } else if (Platform.isIOS || Platform.isMacOS) {
      configuration = PurchasesConfiguration(_appleApiKey);
    }

    if (configuration != null) {
      await Purchases.configure(configuration);
    }
  }

  /// Checks if the user is currently PRO based on the RevenueCat servers
  static Future<bool> isUserPremium() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[entitlementId]?.isActive == true;
    } catch (e) {
      debugPrint("Failed to fetch customer info: $e");
      return false;
    }
  }

  /// Restores previous purchases (e.g., if a user reinstalls the app)
  static Future<bool> restorePurchases() async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all[entitlementId]?.isActive == true;
    } catch (e) {
      debugPrint("Failed to restore purchases: $e");
      return false;
    }
  }

  /// Fetches the available subscription packages from RevenueCat
  static Future<List<Package>> getOfferings() async {
    try {
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
        return offerings.current!.availablePackages;
      }
    } catch (e) {
      debugPrint("Failed to fetch offerings: $e");
    }
    return [];
  }

  /// Attempts to purchase the given package
  static Future<bool> purchasePackage(Package package) async {
    try {
      PurchaseResult result = await Purchases.purchasePackage(package);
      return result.customerInfo.entitlements.all[entitlementId]?.isActive == true;
    } catch (e) {
      debugPrint("Purchase cancelled or failed: $e");
      return false;
    }
  }
}
