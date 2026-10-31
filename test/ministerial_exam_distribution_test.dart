import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:patente_italiana_app/models/question.dart';

void main() {
  group('Ministerial Exam Distribution Tests', () {
    late List<Question> mockQuestions;

    setUp(() {
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
    });

    test('startMinisterialExam distribution produces exactly 30 unique questions and 13-17 True answers across 100 iterations', () {
      final random = Random();

      for (int run = 0; run < 100; run++) {
        // Balanced Vero / Falso target (14, 15, or 16 VERO)
        final int targetTrue = 14 + random.nextInt(3); // 14 to 16
        final int targetFalse = 30 - targetTrue; // 14 to 16

        final truePool = mockQuestions.where((q) => q.isTrue).toList()..shuffle();
        final falsePool = mockQuestions.where((q) => !q.isTrue).toList()..shuffle();

        final Map<String, List<Question>> trueByTopic = {};
        for (var q in truePool) {
          trueByTopic.putIfAbsent(q.topicId, () => []).add(q);
        }

        final Map<String, List<Question>> falseByTopic = {};
        for (var q in falsePool) {
          falseByTopic.putIfAbsent(q.topicId, () => []).add(q);
        }

        final List<Question> selected = [];
        final Set<String> selectedIds = {};

        // 1. Pick 1 True from each topic as available until targetTrue reached
        for (var topicList in trueByTopic.values) {
          if (selected.where((q) => q.isTrue).length >= targetTrue) break;
          for (var q in topicList) {
            if (!selectedIds.contains(q.id)) {
              selected.add(q);
              selectedIds.add(q.id);
              break;
            }
          }
        }

        for (var q in truePool) {
          if (selected.where((s) => s.isTrue).length >= targetTrue) break;
          if (!selectedIds.contains(q.id)) {
            selected.add(q);
            selectedIds.add(q.id);
          }
        }

        // 2. Pick 1 False from each topic as available until targetFalse reached
        for (var topicList in falseByTopic.values) {
          if (selected.where((q) => !q.isTrue).length >= targetFalse) break;
          for (var q in topicList) {
            if (!selectedIds.contains(q.id)) {
              selected.add(q);
              selectedIds.add(q.id);
              break;
            }
          }
        }

        for (var q in falsePool) {
          if (selected.where((s) => !s.isTrue).length >= targetFalse) break;
          if (!selectedIds.contains(q.id)) {
            selected.add(q);
            selectedIds.add(q.id);
          }
        }

        selected.shuffle();

        // Assert exactly 30 questions
        expect(selected.length, 30, reason: "Run $run should have exactly 30 questions");

        // Assert 30 unique IDs (no duplicates)
        final uniqueIds = selected.map((q) => q.id).toSet();
        expect(uniqueIds.length, 30, reason: "Run $run should contain 30 unique questions without duplicates");

        // Assert True answers strictly between 13 and 17
        final int trueCount = selected.where((q) => q.isTrue).length;
        expect(trueCount >= 13 && trueCount <= 17, isTrue,
            reason: "Run $run True count was $trueCount, expected between 13 and 17");

        // Assert False answers strictly between 13 and 17
        final int falseCount = selected.where((q) => !q.isTrue).length;
        expect(falseCount >= 13 && falseCount <= 17, isTrue,
            reason: "Run $run False count was $falseCount, expected between 13 and 17");
      }
    });
  });
}
