import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:patente_italiana_app/providers/language_provider.dart';
import 'package:patente_italiana_app/providers/subscription_provider.dart';
import 'package:patente_italiana_app/screens/ai_tutor_screen.dart';
import 'package:patente_italiana_app/services/revenuecat_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SubscriptionProvider Offline Survival Tests', () {
    tearDown(() {
      RevenueCatService.testPremiumStatusProvider = null;
    });

    test('SubscriptionProvider reads cached is_premium_active=true and survives failing/unconfigured RevenueCat', () async {
      SharedPreferences.setMockInitialValues({
        'is_premium_active': true,
      });

      // Explicitly simulate offline network failure from RevenueCat
      RevenueCatService.testPremiumStatusProvider = () async {
        throw Exception('Network unreachable / offline');
      };

      final provider = SubscriptionProvider();

      // Allow async _loadState to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(provider.isPremium, isTrue, reason: 'Cached PRO status must be retained when RevenueCat fails offline');

      // Test explicit refresh failure also retains cached true
      await provider.refreshSubscriptionStatus();
      expect(provider.isPremium, isTrue, reason: 'Explicit refresh on offline failure must retain cached PRO status');

      // Verify SharedPreferences was NOT overwritten with false
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('is_premium_active'), isTrue);
    });

    test('SubscriptionProvider reads cached is_premium_active=true when RevenueCat returns null (unconfigured)', () async {
      SharedPreferences.setMockInitialValues({
        'is_premium_active': true,
      });

      // Simulate unconfigured RevenueCat returning null
      RevenueCatService.testPremiumStatusProvider = () async => null;

      final provider = SubscriptionProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(provider.isPremium, isTrue);
    });

    test('SubscriptionProvider overwrites cached PRO only when RevenueCat successfully returns server response', () async {
      SharedPreferences.setMockInitialValues({
        'is_premium_active': true,
      });

      // Simulate verified server response that subscription has ended (false)
      RevenueCatService.testPremiumStatusProvider = () async => false;

      final provider = SubscriptionProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(provider.isPremium, isFalse, reason: 'Verified server response of false must update PRO status');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('is_premium_active'), isFalse);
    });
  });

  group('AI Tutor Daily Quota Persistence Tests', () {
    testWidgets('AiTutorScreen restores saved quota from SharedPreferences for today', (WidgetTester tester) async {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      SharedPreferences.setMockInitialValues({
        'key_ai_tutor_count': 2,
        'key_ai_tutor_date': today,
      });

      final subProvider = SubscriptionProvider();
      final langProvider = LanguageProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SubscriptionProvider>.value(value: subProvider),
            ChangeNotifierProvider<LanguageProvider>.value(value: langProvider),
          ],
          child: const MaterialApp(
            home: AiTutorScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Assert that the header displays the restored 2/3 quota
      expect(find.textContaining('Domande oggi: 2/3'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('AiTutorScreen rolls over quota to 0/3 when saved date is yesterday', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'key_ai_tutor_count': 3,
        'key_ai_tutor_date': '2026-10-31', // yesterday
      });

      final subProvider = SubscriptionProvider();
      final langProvider = LanguageProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SubscriptionProvider>.value(value: subProvider),
            ChangeNotifierProvider<LanguageProvider>.value(value: langProvider),
          ],
          child: const MaterialApp(
            home: AiTutorScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Assert that date rollover reset count to 0/3
      expect(find.textContaining('Domande oggi: 0/3'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      expect(prefs.getString('key_ai_tutor_date'), today);
      expect(prefs.getInt('key_ai_tutor_count'), 0);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
