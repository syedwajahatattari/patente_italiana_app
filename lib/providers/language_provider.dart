import 'package:flutter/material.dart';
import '../services/storage_service.dart';

enum AppLanguage { urdu, italian, english, romanUrdu }

class LanguageProvider extends ChangeNotifier {
  AppLanguage _language = AppLanguage.urdu;

  AppLanguage get language => _language;
  String get langCode {
    switch (_language) {
      case AppLanguage.urdu:
        return 'ur';
      case AppLanguage.italian:
        return 'it';
      case AppLanguage.english:
        return 'en';
      case AppLanguage.romanUrdu:
        return 'roman';
    }
  }

  LanguageProvider() {
    _loadLanguage();
  }

  void _loadLanguage() async {
    final code = await StorageService.getLanguage();
    if (code == 'it') {
      _language = AppLanguage.italian;
    } else if (code == 'en') {
      _language = AppLanguage.english;
    } else if (code == 'roman') {
      _language = AppLanguage.romanUrdu;
    } else {
      _language = AppLanguage.urdu;
    }
    notifyListeners();
  }

  void setLanguage(AppLanguage lang) async {
    _language = lang;
    String code = 'ur';
    if (lang == AppLanguage.italian) code = 'it';
    if (lang == AppLanguage.english) code = 'en';
    if (lang == AppLanguage.romanUrdu) code = 'roman';
    await StorageService.setLanguage(code);
    notifyListeners();
  }
}
