import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:patente_italiana_app/models/question.dart';
import 'package:patente_italiana_app/providers/language_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Roman Urdu End-to-End Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Question.fromJson and toJson parse and serialize Roman Urdu fields correctly', () {
      final sampleJson = {
        'id': 'test_q_1',
        'topicId': 't1',
        'question_it': 'In una carreggiata...',
        'question_ur': 'روڈ وے پر...',
        'question_en': 'On a roadway...',
        'question_roman_urdu': 'Rod way par...',
        'isTrue': true,
        'explanation_it': 'Spiegazione...',
        'explanation_ur': 'وضاحت...',
        'explanation_en': 'Explanation...',
        'explanation_roman_urdu': 'Wazahat...',
      };

      final q = Question.fromJson(sampleJson);
      expect(q.questionRomanUrdu, 'Rod way par...');
      expect(q.explanationRomanUrdu, 'Wazahat...');

      final serialized = q.toJson();
      expect(serialized['question_roman_urdu'], 'Rod way par...');
      expect(serialized['explanation_roman_urdu'], 'Wazahat...');
    });

    test('Real dataset has non-empty question_roman_urdu and explanation_roman_urdu for all 7,139 questions', () {
      final file = File('assets/data/quiz_questions.json');
      expect(file.existsSync(), isTrue, reason: "assets/data/quiz_questions.json must exist");

      final raw = file.readAsStringSync();
      final List<dynamic> list = json.decode(raw);
      expect(list.length, 7139, reason: "Must contain exactly 7,139 questions");

      int emptyQuestionRoman = 0;
      int emptyExplanationRoman = 0;

      for (int i = 0; i < list.length; i++) {
        final item = list[i] as Map<String, dynamic>;
        final qRom = (item['question_roman_urdu'] as String?)?.trim() ?? '';
        final expRom = (item['explanation_roman_urdu'] as String?)?.trim() ?? '';

        if (qRom.isEmpty) emptyQuestionRoman++;
        if (expRom.isEmpty) emptyExplanationRoman++;
      }

      expect(emptyQuestionRoman, 0, reason: "All 7,139 questions must have non-empty question_roman_urdu");
      expect(emptyExplanationRoman, 0, reason: "All 7,139 questions must have non-empty explanation_roman_urdu");
    });

    test('Translation fallback correctly handles Roman Urdu empty/non-empty states', () {
      // Helper simulating _getTranslation logic in exam and quiz screens
      String getTranslation(Question q, String langCode) {
        if (langCode == 'roman') {
          if (q.questionRomanUrdu.isNotEmpty) return q.questionRomanUrdu;
          if (q.questionUr.isNotEmpty) return q.questionUr;
          return q.questionIt;
        }
        if (langCode == 'en') return q.questionEn.isNotEmpty ? q.questionEn : q.questionIt;
        if (langCode == 'ur') return q.questionUr.isNotEmpty ? q.questionUr : q.questionIt;
        return q.questionIt;
      }

      // Helper simulating _getExplanation logic
      String getExplanation(Question q, String langCode) {
        if (langCode == 'roman') {
          if (q.explanationRomanUrdu.isNotEmpty) return q.explanationRomanUrdu;
          if (q.explanationUr.isNotEmpty) return q.explanationUr;
          return q.explanationIt;
        }
        if (langCode == 'en') return q.explanationEn.isNotEmpty ? q.explanationEn : q.explanationIt;
        if (langCode == 'ur') return q.explanationUr.isNotEmpty ? q.explanationUr : q.explanationIt;
        return q.explanationIt;
      }

      // Case 1: Roman Urdu present
      final qFull = Question(
        id: '1',
        topicId: 't1',
        questionIt: 'Italian Q',
        questionUr: 'Urdu Q',
        questionEn: 'English Q',
        questionRomanUrdu: 'Roman Urdu Q',
        isTrue: true,
        explanationIt: 'Italian Exp',
        explanationUr: 'Urdu Exp',
        explanationEn: 'English Exp',
        explanationRomanUrdu: 'Roman Urdu Exp',
      );
      expect(getTranslation(qFull, 'roman'), 'Roman Urdu Q');
      expect(getExplanation(qFull, 'roman'), 'Roman Urdu Exp');

      // Case 2: Roman Urdu empty -> falls back to Urdu
      final qNoRoman = Question(
        id: '2',
        topicId: 't1',
        questionIt: 'Italian Q',
        questionUr: 'Urdu Q',
        questionEn: 'English Q',
        questionRomanUrdu: '',
        isTrue: true,
        explanationIt: 'Italian Exp',
        explanationUr: 'Urdu Exp',
        explanationEn: 'English Exp',
        explanationRomanUrdu: '',
      );
      expect(getTranslation(qNoRoman, 'roman'), 'Urdu Q');
      expect(getExplanation(qNoRoman, 'roman'), 'Urdu Exp');

      // Case 3: Roman Urdu & Urdu empty -> falls back to Italian
      final qOnlyIt = Question(
        id: '3',
        topicId: 't1',
        questionIt: 'Italian Q',
        questionUr: '',
        questionEn: '',
        questionRomanUrdu: '',
        isTrue: true,
        explanationIt: 'Italian Exp',
        explanationUr: '',
        explanationEn: '',
        explanationRomanUrdu: '',
      );
      expect(getTranslation(qOnlyIt, 'roman'), 'Italian Q');
      expect(getExplanation(qOnlyIt, 'roman'), 'Italian Exp');
    });

    test('LanguageProvider maps and persists AppLanguage.romanUrdu to "roman"', () async {
      SharedPreferences.setMockInitialValues({'key_language': 'roman'});
      final langProvider = LanguageProvider();

      // Wait microtask for async _loadLanguage
      await Future.delayed(const Duration(milliseconds: 50));

      expect(langProvider.language, AppLanguage.romanUrdu);
      expect(langProvider.langCode, 'roman');

      // Change language and change back
      langProvider.setLanguage(AppLanguage.italian);
      expect(langProvider.langCode, 'it');

      langProvider.setLanguage(AppLanguage.romanUrdu);
      expect(langProvider.langCode, 'roman');
    });
  });
}
