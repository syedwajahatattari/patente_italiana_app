import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/revenuecat_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  static const String _prefKeyIsPremium = 'is_premium_active';
  static const String _prefKeyExamCount = 'daily_exam_count';
  static const String _prefKeyExamDate = 'daily_exam_date';

  bool _isPremium = false;
  int _dailyExamsTaken = 0;
  final int maxDailyFreeExams = 3;
  bool _isRestoring = false;

  bool get isPremium => _isPremium;
  int get dailyExamsTaken => _dailyExamsTaken;
  int get remainingDailyExams => _isPremium ? 999 : (maxDailyFreeExams - _dailyExamsTaken).clamp(0, maxDailyFreeExams);
  bool get canTakeExam => _isPremium || _dailyExamsTaken < maxDailyFreeExams;
  bool get isRestoring => _isRestoring;

  SubscriptionProvider() {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Sync subscription state with RevenueCat servers in background
    bool isPremiumActive = await RevenueCatService.isUserPremium();
    _isPremium = isPremiumActive;
    await prefs.setBool(_prefKeyIsPremium, isPremiumActive);

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString(_prefKeyExamDate) ?? '';
    if (savedDate == today) {
      _dailyExamsTaken = prefs.getInt(_prefKeyExamCount) ?? 0;
    } else {
      _dailyExamsTaken = 0;
      await prefs.setString(_prefKeyExamDate, today);
      await prefs.setInt(_prefKeyExamCount, 0);
    }
    notifyListeners();
  }

  /// Refreshes state explicitly from RevenueCat
  Future<void> refreshSubscriptionStatus() async {
    bool isPremiumActive = await RevenueCatService.isUserPremium();
    _isPremium = isPremiumActive;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyIsPremium, isPremiumActive);
    notifyListeners();
  }

  /// Restore previous purchases (required for App Store compliance)
  Future<bool> restorePurchases() async {
    _isRestoring = true;
    notifyListeners();

    try {
      final restored = await RevenueCatService.restorePurchases();
      _isPremium = restored;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyIsPremium, restored);
      return restored;
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  /// FOR TESTING / DEBUG ONLY: Toggle premium manually. 
  /// In production, rely on `refreshSubscriptionStatus()` after a purchase.
  Future<void> setPremium(bool value) async {
    _isPremium = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyIsPremium, value);
    notifyListeners();
  }

  Future<void> togglePremium() async {
    await setPremium(!_isPremium);
  }

  Future<bool> recordExamAttempt() async {
    if (_isPremium) return true;
    if (_dailyExamsTaken >= maxDailyFreeExams) return false;

    _dailyExamsTaken++;
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString(_prefKeyExamDate, today);
    await prefs.setInt(_prefKeyExamCount, _dailyExamsTaken);
    notifyListeners();
    return true;
  }

  /// Topics 0 to 4 (Topics 1 to 5) are completely free, remaining require PRO
  bool isTopicUnlocked(int topicIndex) {
    if (_isPremium) return true;
    return topicIndex < 5;
  }

  /// First 3 hints/tricks are free, remaining require PRO
  bool isTrickUnlocked(int trickIndex) {
    if (_isPremium) return true;
    return trickIndex < 3;
  }
}
