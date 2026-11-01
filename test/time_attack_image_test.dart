import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:patente_italiana_app/models/question.dart';
import 'package:patente_italiana_app/providers/language_provider.dart';
import 'package:patente_italiana_app/providers/quiz_provider.dart';
import 'package:patente_italiana_app/providers/subscription_provider.dart';
import 'package:patente_italiana_app/screens/time_attack_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestableTimeAttackScreen(List<Question> questions) {
    final quizProvider = QuizProvider()..setQuestionsForTesting(questions);
    final langProvider = LanguageProvider();
    final subProvider = SubscriptionProvider();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<QuizProvider>.value(value: quizProvider),
        ChangeNotifierProvider<LanguageProvider>.value(value: langProvider),
        ChangeNotifierProvider<SubscriptionProvider>.value(value: subProvider),
      ],
      child: const MaterialApp(
        home: TimeAttackScreen(),
      ),
    );
  }

  group('Time Attack Question Image Display Tests', () {
    testWidgets('Shows CachedNetworkImage when question has non-empty imageUrl', (WidgetTester tester) async {
      final questionWithImage = Question(
        id: 'q_test_with_img',
        topicId: 't1',
        questionIt: 'Il segnale raffigurato preannuncia un pericolo.',
        questionUr: 'دکھایا گیا نشان خطرے کا اعلان کرتا ہے۔',
        questionEn: 'The sign depicted warns of danger.',
        questionRomanUrdu: 'Dikhaya gaya nishan khatre ka ailaan karta hai.',
        isTrue: true,
        explanationIt: 'Spiegazione del segnale...',
        explanationUr: 'سگنل کی وضاحت...',
        explanationEn: 'Sign explanation...',
        explanationRomanUrdu: 'Signal ki wazahat...',
        imageUrl: 'https://raw.githubusercontent.com/Ed0ardo/QuizPatenteB/master/segnali/1.png',
      );

      await tester.pumpWidget(buildTestableTimeAttackScreen([questionWithImage]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert CachedNetworkImage widget is present with exact ValueKey
      expect(find.byType(CachedNetworkImage), findsOneWidget);
      expect(find.byKey(const ValueKey('img_q_test_with_img')), findsOneWidget);
      expect(find.text('Il segnale raffigurato preannuncia un pericolo.'), findsOneWidget);

      // Cleanly teardown by pumping a replacement widget to dispose the screen timer
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Does not show CachedNetworkImage when question has null or empty imageUrl', (WidgetTester tester) async {
      final questionWithoutImage = Question(
        id: 'q_test_no_img',
        topicId: 't1',
        questionIt: 'La distanza di sicurezza deve essere sempre mantenuta.',
        questionUr: 'حفاظتی فاصلہ ہمیشہ برقرار رکھنا چاہیے۔',
        questionEn: 'Safe distance must always be maintained.',
        questionRomanUrdu: 'Hifazati faasla hamesha barqarar rakhna chahiye.',
        isTrue: true,
        explanationIt: 'Spiegazione distanza...',
        explanationUr: 'فاصلے کی وضاحت...',
        explanationEn: 'Distance explanation...',
        explanationRomanUrdu: 'Faasla ki wazahat...',
        imageUrl: null,
      );

      await tester.pumpWidget(buildTestableTimeAttackScreen([questionWithoutImage]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert no image widget or key is present
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byKey(const ValueKey('img_q_test_no_img')), findsNothing);
      expect(find.text('La distanza di sicurezza deve essere sempre mantenuta.'), findsOneWidget);

      // Cleanly teardown
      await tester.pumpWidget(const SizedBox());
    });
  });
}
