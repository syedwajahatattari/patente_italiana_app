import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenRouterService {
  static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  // Configurable models with automatic fallback
  static const String _primaryModel = 'google/gemma-7b-it:free';
  static const String _fallbackModel = 'meta-llama/llama-3-8b-instruct:free';

  /// Obtains the API key primarily from --dart-define=OPENROUTER_API_KEY=...
  /// with safe fallback to local unbundled .env if present during dev.
  static String get apiKey {
    const fromDefine = String.fromEnvironment('OPENROUTER_API_KEY', defaultValue: '');
    if (fromDefine.isNotEmpty) return fromDefine;
    if (dotenv.isInitialized) {
      return dotenv.env['OPENROUTER_API_KEY'] ?? '';
    }
    return '';
  }

  static Future<String> getAiResponse(String systemPrompt, String userMessage) async {
    final key = apiKey;
    if (key.isEmpty) {
      return "Chiave API non configurata. Imposta OPENROUTER_API_KEY tramite --dart-define.\n(AI سروس کی کنفیگریشن درکار ہے)";
    }

    // Attempt 1: Primary Model
    String? response = await _requestModel(_primaryModel, systemPrompt, userMessage, key);
    if (response != null && response.isNotEmpty) return response;

    // Attempt 2: Fallback Model
    debugPrint("Primary AI model failed or timed out. Switching to fallback model: $_fallbackModel");
    response = await _requestModel(_fallbackModel, systemPrompt, userMessage, key);
    if (response != null && response.isNotEmpty) return response;

    return "Impossibile collegarsi al server AI. Riprova più tardi.\n(AI سرور سے رابطہ نہیں ہو سکا، براہ کرم بعد میں کوشش کریں)";
  }

  static Future<String?> _requestModel(
    String model,
    String systemPrompt,
    String userMessage,
    String key,
  ) async {
    try {
      final response = await http
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

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is Map && data['choices'] is List && (data['choices'] as List).isNotEmpty) {
          final firstChoice = data['choices'][0];
          if (firstChoice is Map && firstChoice['message'] is Map) {
            final content = firstChoice['message']['content'];
            if (content is String && content.trim().isNotEmpty) {
              return content.trim();
            }
          }
        }
      } else {
        debugPrint("OpenRouter model $model responded with code: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("OpenRouter request error for $model: $e");
    }
    return null;
  }
}
