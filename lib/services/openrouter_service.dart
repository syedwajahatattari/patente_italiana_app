import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum AiErrorType {
  none,
  missingKey,
  rateLimited,
  modelNotFound,
  timeout,
  noInternet,
  serverError,
}

class AiResponseResult {
  final bool success;
  final String? text;
  final AiErrorType errorType;
  final String errorMessageIt;
  final String errorMessageUr;
  final int? statusCode;

  const AiResponseResult.success(this.text)
      : success = true,
        errorType = AiErrorType.none,
        errorMessageIt = '',
        errorMessageUr = '',
        statusCode = 200;

  const AiResponseResult.failure({
    required this.errorType,
    required this.errorMessageIt,
    required this.errorMessageUr,
    this.statusCode,
  })  : success = false,
        text = null;
}

class OpenRouterService {
  static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  // Configurable models with automatic fallback
  // Primary: Official OpenRouter Free Models Router (auto-selects available free models)
  // Fallback: Llama 3.2 3B Instruct Free tier
  static const String _primaryModel = 'openrouter/free';
  static const String _fallbackModel = 'meta-llama/llama-3.2-3b-instruct:free';

  /// Optional client injection for unit tests
  @visibleForTesting
  static http.Client? testHttpClient;

  /// Optional API key override for unit tests
  @visibleForTesting
  static String? testApiKey;

  /// Obtains the API key strictly from compile-time environment flag:
  /// `--dart-define=OPENROUTER_API_KEY=...` (or test override if set)
  static String get apiKey =>
      testApiKey ?? const String.fromEnvironment('OPENROUTER_API_KEY', defaultValue: '');

  static bool get isConfigured => apiKey.isNotEmpty;

  /// Primary high-level method returning detailed result with status and error differentiation
  static Future<AiResponseResult> getAiResponseDetailed(
    String systemPrompt,
    String userMessage,
  ) async {
    final key = apiKey;
    if (key.isEmpty) {
      return const AiResponseResult.failure(
        errorType: AiErrorType.missingKey,
        errorMessageIt:
            "Chiave API non configurata.\nImposta OPENROUTER_API_KEY tramite --dart-define.",
        errorMessageUr:
            "AI سروس کی API کی شامل نہیں ہے۔ براہ کرم --dart-define کے ذریعے کنفیگر کریں۔",
        statusCode: 401,
      );
    }

    // Attempt 1: Primary Model
    final attempt1 = await _requestModel(_primaryModel, systemPrompt, userMessage, key);
    if (attempt1.success) return attempt1;

    // Attempt 2: Fallback Model
    debugPrint(
      "Primary AI model ($_primaryModel) failed (${attempt1.errorType}). Switching to fallback model: $_fallbackModel",
    );
    final attempt2 = await _requestModel(_fallbackModel, systemPrompt, userMessage, key);
    if (attempt2.success) return attempt2;

    // Return the most specific failure reason from the attempts
    return attempt2.errorType != AiErrorType.serverError ? attempt2 : attempt1;
  }

  static Future<AiResponseResult> _requestModel(
    String model,
    String systemPrompt,
    String userMessage,
    String key,
  ) async {
    try {
      final client = testHttpClient ?? http.Client();
      final shouldClose = testHttpClient == null;
      http.Response response;
      try {
        response = await client
            .post(
              Uri.parse(_baseUrl),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $key',
                'HTTP-Referer': 'https://patenteitaliana.app',
                'X-Title': 'Patente Italiana App',
              },
              body: jsonEncode({
                'model': model,
                'messages': [
                  {'role': 'system', 'content': systemPrompt},
                  {'role': 'user', 'content': userMessage},
                ],
              }),
            )
            .timeout(const Duration(seconds: 15));
      } finally {
        if (shouldClose) client.close();
      }

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is Map && data['choices'] is List && (data['choices'] as List).isNotEmpty) {
          final firstChoice = data['choices'][0];
          if (firstChoice is Map && firstChoice['message'] is Map) {
            final content = firstChoice['message']['content'];
            if (content is String && content.trim().isNotEmpty) {
              return AiResponseResult.success(content.trim());
            }
          }
        }
        return const AiResponseResult.failure(
          errorType: AiErrorType.serverError,
          errorMessageIt: "Risposta del modello vuota o non valida.",
          errorMessageUr: "ماڈل کا جواب خالی یا غلط تھا۔",
          statusCode: 200,
        );
      } else if (response.statusCode == 429) {
        return const AiResponseResult.failure(
          errorType: AiErrorType.rateLimited,
          errorMessageIt:
              "Limite di richieste superato (429 Too Many Requests).\nRiprova tra qualche istante.",
          errorMessageUr:
              "درخواستوں کی حد پوری ہو چکی ہے (429)، براہ کرم کچھ دیر بعد دوبارہ کوشش کریں۔",
          statusCode: 429,
        );
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return AiResponseResult.failure(
          errorType: AiErrorType.missingKey,
          errorMessageIt:
              "Chiave API OpenRouter non valida o non autorizzata (${response.statusCode}).",
          errorMessageUr:
              "اوپن راؤٹر API کی غلط یا غیر مجاز ہے۔",
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 404 || response.statusCode == 503) {
        return AiResponseResult.failure(
          errorType: AiErrorType.modelNotFound,
          errorMessageIt:
              "Modello AI temporaneamente non disponibile (${response.statusCode}).",
          errorMessageUr:
              "AI ماڈل فی الحال دستیاب نہیں ہے۔",
          statusCode: response.statusCode,
        );
      } else {
        return AiResponseResult.failure(
          errorType: AiErrorType.serverError,
          errorMessageIt:
              "Errore del server AI (Codice: ${response.statusCode}). Riprova più tardi.",
          errorMessageUr:
              "AI سرور میں خرابی (کوڈ: ${response.statusCode})، براہ کرم بعد میں کوشش کریں۔",
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      return const AiResponseResult.failure(
        errorType: AiErrorType.timeout,
        errorMessageIt:
            "Tempo di attesa scaduto (Timeout oltre 15s). Il server AI non risponde.",
        errorMessageUr:
            "سرور کا رسپانس ٹائم آؤٹ ہو گیا ہے۔ براہ کرم دوبارہ کوشش کریں۔",
      );
    } on SocketException {
      return const AiResponseResult.failure(
        errorType: AiErrorType.noInternet,
        errorMessageIt:
            "Nessuna connessione internet. Verifica la tua rete.",
        errorMessageUr:
            "انٹرنیٹ کنکشن موجود نہیں ہے، براہ کرم نیٹ ورک چیک کریں۔",
      );
    } catch (e) {
      debugPrint("OpenRouter request error for $model: $e");
      return AiResponseResult.failure(
        errorType: AiErrorType.serverError,
        errorMessageIt: "Errore di comunicazione: $e",
        errorMessageUr: "رابطے کی خرابی، براہ کرم بعد میں کوشش کریں۔",
      );
    }
  }
}
