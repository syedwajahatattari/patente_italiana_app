import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isSpeaking = false;
  static bool _isInitialized = false;

  /// Holds the unique ID of the currently playing audio snippet (e.g. "q123_it", "q123_ur_exp")
  /// Allows UI widgets to reactively display active stop/play states.
  static final ValueNotifier<String?> currentPlayingId = ValueNotifier<String?>(null);

  static bool get isSpeaking => _isSpeaking;

  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        currentPlayingId.value = null;
      });

      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
        currentPlayingId.value = null;
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint("TTSService Error: $msg");
        _isSpeaking = false;
        currentPlayingId.value = null;
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint("TTSService init failed: $e");
    }
  }

  /// Speaks text with specific language configuration.
  /// Supported [langCode]: 'it' (Italian), 'ur' (Urdu), 'en' (English).
  static Future<void> speak(
    String text, {
    String langCode = 'it',
    String? id,
  }) async {
    if (text.trim().isEmpty) return;
    await init();

    if (_isSpeaking) {
      await stop();
    }

    try {
      if (langCode == 'it') {
        await _flutterTts.setLanguage("it-IT");
        await _flutterTts.setSpeechRate(0.45);
      } else if (langCode == 'ur') {
        // Configure Urdu TTS with clear pacing
        final isAvailable = await _flutterTts.isLanguageAvailable("ur-PK");
        if (isAvailable == 1 || isAvailable == true) {
          await _flutterTts.setLanguage("ur-PK");
        } else {
          await _flutterTts.setLanguage("ur");
        }
        await _flutterTts.setSpeechRate(0.38); // Slower rate for clear Urdu diction
      } else {
        await _flutterTts.setLanguage("en-US");
        await _flutterTts.setSpeechRate(0.48);
      }

      _isSpeaking = true;
      currentPlayingId.value = id ?? text.hashCode.toString();
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint("TTSService speak error: $e");
      _isSpeaking = false;
      currentPlayingId.value = null;
    }
  }

  /// Toggles playback: stops if this specific ID is already playing, or starts speaking.
  static Future<void> toggleSpeak({
    required String id,
    required String text,
    String langCode = 'it',
  }) async {
    if (_isSpeaking && currentPlayingId.value == id) {
      await stop();
    } else {
      await speak(text, langCode: langCode, id: id);
    }
  }

  static Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint("TTSService stop error: $e");
    } finally {
      _isSpeaking = false;
      currentPlayingId.value = null;
    }
  }
}
