import 'dart:async';
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
      RevenueCatService.testRestorePurchasesProvider = null;
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

    test('SubscriptionProvider.restorePurchases retains cached PRO when RevenueCat fails or throws offline', () async {
      SharedPreferences.setMockInitialValues({
        'is_premium_active': true,
      });

      // Simulate offline network failure during restore
      RevenueCatService.testRestorePurchasesProvider = () async {
        throw Exception('Network unreachable / offline');
      };

      final provider = SubscriptionProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(provider.isPremium, isTrue);

      final restored = await provider.restorePurchases();
      expect(restored, isTrue, reason: 'restorePurchases must return current PRO status on offline error');
      expect(provider.isPremium, isTrue, reason: 'Cached PRO status must not be wiped when restore fails offline');
      expect(provider.lastRestoreWasVerified, isFalse, reason: 'lastRestoreWasVerified must be false on offline error');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('is_premium_active'), isTrue, reason: 'SharedPreferences must retain is_premium_active=true');
    });

    test('SubscriptionProvider.restorePurchases retains cached PRO when RevenueCat is unconfigured (returns null)', () async {
      SharedPreferences.setMockInitialValues({
        'is_premium_active': true,
      });

      // Simulate unconfigured RevenueCat returning null
      RevenueCatService.testRestorePurchasesProvider = () async => null;

      final provider = SubscriptionProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(provider.isPremium, isTrue);

      final restored = await provider.restorePurchases();
      expect(restored, isTrue);
      expect(provider.isPremium, isTrue);
      expect(provider.lastRestoreWasVerified, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('is_premium_active'), isTrue);
    });

    test('SubscriptionProvider.restorePurchases overwrites cache only when RevenueCat successfully returns server response (false)', () async {
      SharedPreferences.setMockInitialValues({
        'is_premium_active': true,
      });

      // Simulate verified server response that no active subscription exists
      RevenueCatService.testRestorePurchasesProvider = () async => false;

      final provider = SubscriptionProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(provider.isPremium, isTrue);

      final restored = await provider.restorePurchases();
      expect(restored, isFalse, reason: 'Verified server false must update restore result to false');
      expect(provider.isPremium, isFalse, reason: 'Verified server false must overwrite provider PRO status to false');
      expect(provider.lastRestoreWasVerified, isTrue, reason: 'lastRestoreWasVerified must be true on verified server response');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('is_premium_active'), isFalse, reason: 'Verified server false must overwrite SharedPreferences cache');
    });

    test('SubscriptionProvider.restorePurchases sets lastRestoreWasVerified=true and updates PRO when server returns true', () async {
      SharedPreferences.setMockInitialValues({
        'is_premium_active': false,
      });

      RevenueCatService.testRestorePurchasesProvider = () async => true;

      final provider = SubscriptionProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(provider.isPremium, isFalse);

      final restored = await provider.restorePurchases();
      expect(restored, isTrue);
      expect(provider.isPremium, isTrue);
      expect(provider.lastRestoreWasVerified, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('is_premium_active'), isTrue);
    });
  });

  group('AI Tutor Daily Quota Persistence Tests', () {
    tearDown(() {
      AiTutorScreen.testQuotaLoadBlocker = null;
    });

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

    testWidgets('AiTutorScreen guards send until quota is loaded and accepts queries only after load', (WidgetTester tester) async {
      final quotaCompleter = Completer<void>();
      AiTutorScreen.testQuotaLoadBlocker = quotaCompleter;

      final today = DateTime.now().toIso8601String().substring(0, 10);
      SharedPreferences.setMockInitialValues({
        'key_ai_tutor_count': 1,
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

      // BEFORE quota load resolves:
      // 1. Verify send button is visually disabled (shows loading indicator and null onPressed)
      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.onPressed, isNull, reason: 'Send button must be disabled before quota loads');
      expect(find.byType(CircularProgressIndicator), findsOneWidget, reason: 'Subtle spinner must show while quota is loading');
      expect(find.byIcon(Icons.send_rounded), findsNothing, reason: 'Send icon must not show while loading');

      // 2. Attempt to send while not loaded:
      await tester.enterText(find.byType(TextField), 'Test race question');
      await tester.tap(find.byType(IconButton));
      await tester.pump();

      // Assert no question was sent (no user bubble added, controller not cleared, no crash)
      expect(find.byWidgetPredicate((w) => w is Align && w.alignment == Alignment.centerRight), findsNothing,
          reason: 'No user message bubble should be added before quota load');
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'Test race question', reason: 'Input text should not be cleared by disabled send');

      // 3. Now complete quota loading:
      quotaCompleter.complete();
      await tester.pumpAndSettle();

      // Assert quota is loaded:
      expect(find.textContaining('Domande oggi: 1/3'), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
      final enabledButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(enabledButton.onPressed, isNotNull, reason: 'Send button must be enabled after quota loads');

      // 4. Now sending works normally:
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Check that user message bubble was rendered (finds even if scrolled up by _scrollToBottom) and text field cleared
      expect(find.text('Test race question', skipOffstage: false), findsOneWidget);
      final textFieldAfterSend = tester.widget<TextField>(find.byType(TextField));
      expect(textFieldAfterSend.controller?.text, '', reason: 'Input text should be cleared once sent');

      await tester.pumpWidget(const SizedBox());
    });
  });
}

