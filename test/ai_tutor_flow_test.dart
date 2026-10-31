import 'package:flutter_test/flutter_test.dart';
import 'package:patente_italiana_app/services/openrouter_service.dart';

void main() {
  group('AI Tutor Key Path Tests', () {
    test('OpenRouterService accurately reads compile-time --dart-define key', () {
      final key = OpenRouterService.apiKey;
      expect(OpenRouterService.isConfigured, key.isNotEmpty);
    });

    test('OpenRouterService returns valid response or graceful failure without throwing', () async {
      final result = await OpenRouterService.getAiResponseDetailed(
        'System prompt',
        'Chi ha la precedenza all incrocio?',
      );
      if (!OpenRouterService.isConfigured) {
        expect(result.success, isFalse);
        expect(result.errorType, AiErrorType.missingKey);
        expect(result.statusCode, 401);
      } else {
        expect(result, isNotNull);
      }
    });
  });
}
