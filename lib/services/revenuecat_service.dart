import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  // Public SDK Keys loaded from --dart-define or fallback
  static const String _appleApiKey = String.fromEnvironment('REVENUECAT_APPLE_KEY', defaultValue: '');
  static const String _googleApiKey = String.fromEnvironment('REVENUECAT_GOOGLE_KEY', defaultValue: '');

  // The entitlement ID configured in RevenueCat dashboard (e.g. 'pro')
  static const String entitlementId = 'pro';

  static bool _isConfigured = false;
  static bool get isConfigured => _isConfigured;

  /// Optional mock override for testing
  @visibleForTesting
  static Future<bool?> Function()? testPremiumStatusProvider;

  static Future<void> init() async {
    if (kIsWeb) return; // RevenueCat does not support Web currently

    try {
      final key = Platform.isAndroid ? _googleApiKey : _appleApiKey;
      if (key.isEmpty || key.contains('_here')) {
        debugPrint("Warning: RevenueCat API Key not provided. Use --dart-define=REVENUECAT_GOOGLE_KEY=... or REVENUECAT_APPLE_KEY=...");
        _isConfigured = false;
        return;
      }

      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);
      final configuration = PurchasesConfiguration(key);
      await Purchases.configure(configuration);
      _isConfigured = true;
    } catch (e) {
      debugPrint("RevenueCatService init error: $e");
      _isConfigured = false;
    }
  }

  /// Checks if the user is currently PRO based on the RevenueCat servers.
  /// Returns null if RevenueCat is not configured or if an error occurred (e.g. offline).
  static Future<bool?> checkUserPremiumStatus() async {
    if (testPremiumStatusProvider != null) {
      return testPremiumStatusProvider!();
    }
    if (!_isConfigured) return null;
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[entitlementId]?.isActive == true;
    } catch (e) {
      debugPrint("Failed to fetch customer info: $e");
      return null;
    }
  }

  /// Checks if the user is currently PRO based on the RevenueCat servers
  static Future<bool> isUserPremium() async {
    final status = await checkUserPremiumStatus();
    return status ?? false;
  }

  /// Restores previous purchases (required for App Store compliance)
  static Future<bool> restorePurchases() async {
    if (!_isConfigured) {
      debugPrint("Restore purchases skipped: RevenueCat is not configured.");
      return false;
    }
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
    if (!_isConfigured) return [];
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
    if (!_isConfigured) {
      debugPrint("Purchase skipped: RevenueCat is not configured.");
      return false;
    }
    try {
      final PurchaseResult result = await Purchases.purchase(PurchaseParams.package(package));
      return result.customerInfo.entitlements.all[entitlementId]?.isActive == true;
    } catch (e) {
      debugPrint("Purchase cancelled or failed: $e");
      return false;
    }
  }
}
