import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:patente_italiana_app/models/question.dart';
import 'package:patente_italiana_app/providers/quiz_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Ministerial Exam Distribution Tests on QuizProvider', () {
    late QuizProvider quizProvider;
    late List<Question> mockQuestions;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      quizProvider = QuizProvider();
      mockQuestions = [];
      // Generate 200 questions across 20 topics with 50% True and 50% False
      for (int i = 0; i < 200; i++) {
        final topicNum = (i % 20) + 1;
        mockQuestions.add(
          Question(
            id: 'q_$i',
            topicId: 't$topicNum',
            questionIt: 'Domanda $i',
            questionUr: 'سوال $i',
            questionEn: 'Question $i',
            isTrue: i % 2 == 0,
            explanationIt: 'Spiegazione $i',
            explanationUr: 'وضاحت $i',
            explanationEn: 'Explanation $i',
          ),
        );
      }
      quizProvider.setQuestionsForTesting(mockQuestions);
    });

    tearDown(() {
      quizProvider.stopTimer();
    });

    test('startMinisterialExam production code produces exactly 30 unique questions and 13-17 True answers across 100 iterations (mock pool)', () {
      for (int run = 0; run < 100; run++) {
        quizProvider.startMinisterialExam();
        final selected = quizProvider.activeExamQuestions;

        // 1. Assert exactly 30 questions
        expect(selected.length, 30, reason: "Run $run should have exactly 30 questions");

        // 2. Assert 30 unique IDs (no duplicates)
        final uniqueIds = selected.map((q) => q.id).toSet();
        expect(uniqueIds.length, 30, reason: "Run $run should contain 30 unique questions without duplicates");

        // 3. Assert True answers strictly between 13 and 17
        final int trueCount = selected.where((q) => q.isTrue).length;
        expect(
          trueCount >= 13 && trueCount <= 17,
          isTrue,
          reason: "Run $run True count was $trueCount, expected between 13 and 17",
        );

        // 4. Assert False answers strictly between 13 and 17
        final int falseCount = selected.where((q) => !q.isTrue).length;
        expect(
          falseCount >= 13 && falseCount <= 17,
          isTrue,
          reason: "Run $run False count was $falseCount, expected between 13 and 17",
        );

        quizProvider.stopTimer();
      }
    });

    test('startMinisterialExam strictly balances real 7,139-question dataset with skewed topics across 100 iterations', () {
      final file = File('assets/data/quiz_questions.json');
      expect(file.existsSync(), isTrue, reason: "Real questions asset file must exist");

      final raw = file.readAsStringSync();
      final List<dynamic> list = json.decode(raw);
      final realQuestions = list.map((q) => Question.fromJson(q as Map<String, dynamic>)).toList();
      expect(realQuestions.length, 7139, reason: "Real bank must contain 7,139 questions");

      quizProvider.setQuestionsForTesting(realQuestions);

      for (int run = 0; run < 100; run++) {
        quizProvider.startMinisterialExam();
        final selected = quizProvider.activeExamQuestions;

        // 1. Assert exactly 30 questions
        expect(selected.length, 30, reason: "Real dataset run $run must have 30 questions");

        // 2. Assert 30 unique IDs (no duplicates)
        final uniqueIds = selected.map((q) => q.id).toSet();
        expect(uniqueIds.length, 30, reason: "Real dataset run $run must have 30 unique IDs");

        // 3. Assert True answers strictly between 13 and 17
        final int trueCount = selected.where((q) => q.isTrue).length;
        expect(
          trueCount >= 13 && trueCount <= 17,
          isTrue,
          reason: "Real dataset run $run True count was $trueCount (expected 13-17)",
        );

        // 4. Assert False answers strictly between 13 and 17
        final int falseCount = selected.where((q) => !q.isTrue).length;
        expect(
          falseCount >= 13 && falseCount <= 17,
          isTrue,
          reason: "Real dataset run $run False count was $falseCount (expected 13-17)",
        );

        quizProvider.stopTimer();
      }
    });
  });
}
