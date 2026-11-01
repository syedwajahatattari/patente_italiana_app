import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:patente_italiana_app/services/openrouter_service.dart';

void main() {
  group('AI Tutor Key Path & Service Tests', () {
    tearDown(() {
      OpenRouterService.testApiKey = null;
      OpenRouterService.testHttpClient = null;
      OpenRouterService.testPrimaryModel = null;
    });

    test('OpenRouterService detects missing key and returns 401 without network call', () async {
      OpenRouterService.testApiKey = '';
      expect(OpenRouterService.isConfigured, isFalse);

      final result = await OpenRouterService.getAiResponseDetailed(
        'System prompt',
        'Chi ha la precedenza all incrocio?',
      );

      expect(result.success, isFalse);
      expect(result.errorType, AiErrorType.missingKey);
      expect(result.statusCode, 401);
      expect(result.errorMessageIt, contains('OPENROUTER_API_KEY'));
    });

    test('OpenRouterService successfully parses valid 200 response from primary model', () async {
      OpenRouterService.testApiKey = 'sk-or-v1-mock-valid-key';
      expect(OpenRouterService.isConfigured, isTrue);

      OpenRouterService.testHttpClient = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer sk-or-v1-mock-valid-key');
        expect(request.headers['Content-Type'], 'application/json');

        final responsePayload = {
          'choices': [
            {
              'message': {
                'role': 'assistant',
                'content': 'ITALIANO: Ha la precedenza il veicolo da destra.\nURDU: دائیں طرف کی گاڑی کو ترجیح حاصل ہے۔',
              },
            },
          ],
        };

        return http.Response(
          jsonEncode(responsePayload),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await OpenRouterService.getAiResponseDetailed(
        'System prompt',
        'Chi passa per primo?',
      );

      expect(result.success, isTrue);
      expect(result.text, contains('ITALIANO:'));
      expect(result.text, contains('URDU:'));
      expect(result.errorType, AiErrorType.none);
    });

    test('OpenRouterService falls back to secondary model if primary returns 500', () async {
      OpenRouterService.testApiKey = 'sk-or-v1-mock-valid-key';
      int requestCount = 0;

      OpenRouterService.testHttpClient = MockClient((request) async {
        requestCount++;
        final body = jsonDecode(request.body) as Map;
        if (body['model'] == 'openrouter/free') {
          return http.Response('Internal Server Error', 500);
        } else {
          // Fallback model succeeds
          final responsePayload = {
            'choices': [
              {
                'message': {
                  'role': 'assistant',
                  'content': 'Risposta dal modello di fallback.',
                },
              },
            ],
          };
          return http.Response(
            jsonEncode(responsePayload),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
      });

      final result = await OpenRouterService.getAiResponseDetailed(
        'System prompt',
        'Domanda di test',
      );

      expect(requestCount, 2);
      expect(result.success, isTrue);
      expect(result.text, 'Risposta dal modello di fallback.');
    });

    test('OpenRouterService correctly captures 429 rate limit error', () async {
      OpenRouterService.testApiKey = 'sk-or-v1-mock-valid-key';

      OpenRouterService.testHttpClient = MockClient((request) async {
        return http.Response('Rate limit exceeded', 429);
      });

      final result = await OpenRouterService.getAiResponseDetailed(
        'System prompt',
        'Domanda',
      );

      expect(result.success, isFalse);
      expect(result.errorType, AiErrorType.rateLimited);
      expect(result.statusCode, 429);
    });

    test('OpenRouterService catches SocketException as noInternet error', () async {
      OpenRouterService.testApiKey = 'sk-or-v1-mock-valid-key';

      OpenRouterService.testHttpClient = MockClient((request) async {
        throw const SocketException('Failed host lookup');
      });

      final result = await OpenRouterService.getAiResponseDetailed(
        'System prompt',
        'Domanda',
      );

      expect(result.success, isFalse);
      expect(result.errorType, AiErrorType.noInternet);
    });

    test('OpenRouterService catches TimeoutException as timeout error', () async {
      OpenRouterService.testApiKey = 'sk-or-v1-mock-valid-key';

      OpenRouterService.testHttpClient = MockClient((request) async {
        throw TimeoutException('Request exceeded 15 seconds');
      });

      final result = await OpenRouterService.getAiResponseDetailed(
        'System prompt',
        'Domanda',
      );

      expect(result.success, isFalse);
      expect(result.errorType, AiErrorType.timeout);
      expect(result.errorMessageIt, contains('Timeout'));
    });

    test('OpenRouterService fast-fails on 401 without making redundant fallback call', () async {
      OpenRouterService.testApiKey = 'sk-or-v1-invalid-key';
      int requestCount = 0;

      OpenRouterService.testHttpClient = MockClient((request) async {
        requestCount++;
        return http.Response('Unauthorized', 401);
      });

      final result = await OpenRouterService.getAiResponseDetailed(
        'System prompt',
        'Domanda',
      );

      // Must fast-fail immediately on attempt 1
      expect(requestCount, 1);
      expect(result.success, isFalse);
      expect(result.statusCode, 401);
      expect(result.errorType, AiErrorType.missingKey);
    });
  });
}
