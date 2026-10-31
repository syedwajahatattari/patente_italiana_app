import 'package:flutter/material.dart';
import '../services/storage_service.dart';

enum AppLanguage { urdu, italian, english }

class LanguageProvider extends ChangeNotifier {
  AppLanguage _language = AppLanguage.urdu;

  AppLanguage get language => _language;
  String get langCode => _language == AppLanguage.urdu ? 'ur' : (_language == AppLanguage.italian ? 'it' : 'en');

  LanguageProvider() {
    _loadLanguage();
  }

  void _loadLanguage() async {
    final code = await StorageService.getLanguage();
    if (code == 'it') {
      _language = AppLanguage.italian;
    } else if (code == 'en') {
      _language = AppLanguage.english;
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
    await StorageService.setLanguage(code);
    notifyListeners();
  }
}
