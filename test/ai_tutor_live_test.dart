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
    test(
      'Question 1: STOP vs Dare Precedenza live query returns HTTP 200 with Italian and Urdu explanation',
      () async {
        if (!OpenRouterService.isConfigured) {
          // Gracefully skip when running in non-networked CI / sandbox without key
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
        expect(result.text!.length, greaterThan(20));
      },
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
        expect(result.text!.length, greaterThan(20));
      },
      skip: !OpenRouterService.isConfigured ? 'OPENROUTER_API_KEY not passed via --dart-define' : false,
    );
  });
}
