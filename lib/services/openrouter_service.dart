import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenRouterService {
  static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  
  // Using a free model available on OpenRouter
  static const String _model = 'google/gemma-7b-it:free'; 

  static Future<String> getAiResponse(String systemPrompt, String userMessage) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty) {
      return "Error: API Key not found.";
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'https://patenteitaliana.app', // Replace with your actual domain
          'X-Title': 'Patente Italiana App',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        return "Error: Could not fetch response. (Code: ${response.statusCode})";
      }
    } catch (e) {
      return "Error connecting to AI server.";
    }
  }
}
