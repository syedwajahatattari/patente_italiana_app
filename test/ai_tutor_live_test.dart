// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:patente_italiana_app/services/openrouter_service.dart';

const String _tutorSystemPrompt = '''
Sei un istruttore esperto di teoria della patente B italiana.
Rispondi in modo conciso ma molto chiaro e accurato (massimo 4-5 frasi).
Fornisci la regola ufficiale del Codice della Strada se pertinente.
Dopo la spiegazione in italiano, fornisci OBBLIGATORIAMENTE una breve traduzione/spiegazione in lingua URDU (con alfabeto urdu) per aiutare gli studenti pachistani.
Formatta la risposta esattamente così:
ITA: [La tua risposta in italiano]
URDU: [La tua spiegazione in urdu]
''';

void main() {
  group('Live OpenRouter AI Tutor Verification', () {
    tearDown(() {
      OpenRouterService.testPrimaryModel = null;
    });

    test(
      'Question 1: STOP vs Dare Precedenza live query returns HTTP 200 with Italian and Urdu explanation',
      () async {
        if (!OpenRouterService.isConfigured) {
          return;
        }

        const query = 'Qual è la differenza tra segnale di STOP e Dare Precedenza?';
        final stopwatch = Stopwatch()..start();
        final result = await OpenRouterService.getAiResponseDetailed(_tutorSystemPrompt, query);
        stopwatch.stop();

        print('\n============================================================');
        print('LIVE AI TUTOR QUESTION 1: $query');
        print('Elapsed: ${stopwatch.elapsedMilliseconds} ms');
        print('Status: ${result.statusCode}, Error: ${result.errorType}');
        print('------------------------------------------------------------');
        print(result.text);
        print('============================================================\n');

        expect(result.success, isTrue, reason: 'Live OpenRouter call must succeed');
        expect(result.statusCode, 200);
        expect(result.text, isNotNull);
        final text = result.text!;

        // Format assertion: Must contain ITA: and URDU: tags
        expect(
          RegExp(r'\bITA\b|\bITALIANO\b', caseSensitive: false).hasMatch(text),
          isTrue,
          reason: 'Response must include Italian section tag (ITA:)',
        );
        expect(
          RegExp(r'\bURDU\b', caseSensitive: false).hasMatch(text),
          isTrue,
          reason: 'Response must include Urdu section tag (URDU:)',
        );

        // Content assertion: Must discuss STOP and precedenza rules
        expect(
          RegExp(r'STOP', caseSensitive: false).hasMatch(text),
          isTrue,
          reason: 'Response must mention STOP',
        );
        expect(
          RegExp(r'precedenza', caseSensitive: false).hasMatch(text),
          isTrue,
          reason: 'Response must mention precedenza',
        );

        // Language assertion: Urdu section must contain Arabic/Urdu script
        expect(
          RegExp(r'[\u0600-\u06FF]').hasMatch(text),
          isTrue,
          reason: 'Response must contain genuine Urdu/Arabic script characters',
        );
      },
      timeout: const Timeout(Duration(seconds: 90)),
      skip: !OpenRouterService.isConfigured ? 'OPENROUTER_API_KEY not passed via --dart-define' : false,
    );

    test(
      'Question 2: Autostrada speed limits for neopatentati live query returns HTTP 200 with Italian and Urdu explanation',
      () async {
        if (!OpenRouterService.isConfigured) {
          return;
        }

        const query = 'Quali sono i limiti di velocità per i neopatentati in autostrada?';
        final stopwatch = Stopwatch()..start();
        final result = await OpenRouterService.getAiResponseDetailed(_tutorSystemPrompt, query);
        stopwatch.stop();

        print('\n============================================================');
        print('LIVE AI TUTOR QUESTION 2: $query');
        print('Elapsed: ${stopwatch.elapsedMilliseconds} ms');
        print('Status: ${result.statusCode}, Error: ${result.errorType}');
        print('------------------------------------------------------------');
        print(result.text);
        print('============================================================\n');

        expect(result.success, isTrue, reason: 'Live OpenRouter call must succeed');
        expect(result.statusCode, 200);
        expect(result.text, isNotNull);
        final text = result.text!;

        // Format assertion: Must contain ITA: and URDU: tags
        expect(
          RegExp(r'\bITA\b|\bITALIANO\b', caseSensitive: false).hasMatch(text),
          isTrue,
          reason: 'Response must include Italian section tag (ITA:)',
        );
        expect(
          RegExp(r'\bURDU\b', caseSensitive: false).hasMatch(text),
          isTrue,
          reason: 'Response must include Urdu section tag (URDU:)',
        );

        // Content assertion: Must strictly require the 100 km/h limit (CdS art. 117)
        expect(
          RegExp(r'\b100\b').hasMatch(text),
          isTrue,
          reason: 'Response must explicitly mention the 100 km/h autostrada speed limit',
        );
        expect(
          RegExp(r'neopatentat|patente', caseSensitive: false).hasMatch(text),
          isTrue,
          reason: 'Response must mention neopatentati or patente context',
        );

        // Language assertion: Urdu section must contain Arabic/Urdu script
        expect(
          RegExp(r'[\u0600-\u06FF]').hasMatch(text),
          isTrue,
          reason: 'Response must contain genuine Urdu/Arabic script characters',
        );
      },
      timeout: const Timeout(Duration(seconds: 90)),
      skip: !OpenRouterService.isConfigured ? 'OPENROUTER_API_KEY not passed via --dart-define' : false,
    );

    test(
      'Live Fallback Execution: When primary model fails live, fallback model cohere/north-mini-code:free returns HTTP 200',
      () async {
        if (!OpenRouterService.isConfigured) {
          return;
        }

        // Force primary failure against the real live OpenRouter API
        OpenRouterService.testPrimaryModel = 'nonexistent-model-to-trigger-live-fallback:free';

        const query = 'Cosa indica la luce gialla lampeggiante del semaforo?';
        final stopwatch = Stopwatch()..start();
        final result = await OpenRouterService.getAiResponseDetailed(_tutorSystemPrompt, query);
        stopwatch.stop();

        print('\n============================================================');
        print('LIVE AI TUTOR FALLBACK TEST: $query');
        print('Elapsed: ${stopwatch.elapsedMilliseconds} ms');
        print('Status: ${result.statusCode}, Error: ${result.errorType}');
        print('------------------------------------------------------------');
        print(result.text);
        print('============================================================\n');

        expect(result.success, isTrue, reason: 'Live fallback call must succeed with HTTP 200');
        expect(result.statusCode, 200);
        expect(result.text, isNotNull);
        final text = result.text!;

        expect(
          RegExp(r'[\u0600-\u06FF]').hasMatch(text),
          isTrue,
          reason: 'Fallback response must also contain genuine Urdu/Arabic script',
        );
      },
      timeout: const Timeout(Duration(seconds: 90)),
      skip: !OpenRouterService.isConfigured ? 'OPENROUTER_API_KEY not passed via --dart-define' : false,
    );
  });
}
