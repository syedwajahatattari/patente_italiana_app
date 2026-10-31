import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exam_result.dart';

class StorageService {
  static const String _keyExamResults = 'key_exam_results';
  static const String _keyErrorBank = 'key_error_bank_qids';
  static const String _keyThemeMode = 'key_theme_mode';
  static const String _keyLanguage = 'key_language';
  static const String _keyStreak = 'key_daily_streak';
  static const String _keyStreakDate = 'key_streak_last_date';
  static const String _keyOnboardingDone = 'key_onboarding_done';
  static const String _keyTodayQuestions = 'key_today_questions_count';
  static const String _keyTodayQuestionsDate = 'key_today_questions_date';
  static const String _keyTargetExamDate = 'key_target_exam_date';
  static const String _keyTimeAttackHighScore = 'key_time_attack_high_score';
  static const String _keyTimeAttackGamesPlayedDate = 'key_time_attack_games_date';
  static const String _keyTimeAttackGamesCount = 'key_time_attack_games_count';
  static const String _keyActiveExam = 'key_active_exam_state';
  static const String _keyErrorStreakPrefix = 'key_err_correct_streak_';

  // Exam History
  static Future<List<ExamResult>> getExamResults() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyExamResults) ?? [];
    return raw.map((item) => ExamResult.fromJson(json.decode(item))).toList();
  }

  static Future<void> saveExamResult(ExamResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final results = await getExamResults();
    results.insert(0, result);
    final rawList = results.map((r) => json.encode(r.toJson())).toList();
    await prefs.setStringList(_keyExamResults, rawList);
  }

  // Error Bank (Mistakes)
  static Future<Set<String>> getErrorBankQuestionIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyErrorBank) ?? [];
    return raw.toSet();
  }

  static Future<void> addErrorQuestionId(String qId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getErrorBankQuestionIds();
    current.add(qId);
    await prefs.setStringList(_keyErrorBank, current.toList());
  }

  static Future<void> removeErrorQuestionId(String qId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getErrorBankQuestionIds();
    current.remove(qId);
    await prefs.setStringList(_keyErrorBank, current.toList());
  }

  // ── Daily Streak ──
  static Future<Map<String, int>> getStreakData() async {
    final prefs = await SharedPreferences.getInstance();
    final streak = prefs.getInt(_keyStreak) ?? 0;
    final lastDate = prefs.getString(_keyStreakDate) ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);

    if (lastDate == today) {
      return {'streak': streak, 'updatedToday': 1};
    } else if (lastDate == yesterday) {
      return {'streak': streak, 'updatedToday': 0};
    } else {
      // Streak broken — reset
      await prefs.setInt(_keyStreak, 0);
      return {'streak': 0, 'updatedToday': 0};
    }
  }

  static Future<int> incrementStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final data = await getStreakData();
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (data['updatedToday'] == 1) return data['streak']!;

    final newStreak = data['streak']! + 1;
    await prefs.setInt(_keyStreak, newStreak);
    await prefs.setString(_keyStreakDate, today);
    return newStreak;
  }

  // ── Today's Questions Practiced ──
  static Future<int> getTodayQuestionsPracticed() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString(_keyTodayQuestionsDate) ?? '';
    if (savedDate != today) {
      await prefs.setString(_keyTodayQuestionsDate, today);
      await prefs.setInt(_keyTodayQuestions, 0);
      return 0;
    }
    return prefs.getInt(_keyTodayQuestions) ?? 0;
  }

  static Future<void> addTodayQuestionsPracticed(int count) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString(_keyTodayQuestionsDate) ?? '';
    int current = 0;
    if (savedDate == today) {
      current = prefs.getInt(_keyTodayQuestions) ?? 0;
    }
    await prefs.setString(_keyTodayQuestionsDate, today);
    await prefs.setInt(_keyTodayQuestions, current + count);
  }

  // ── Target Exam Date ──
  static Future<DateTime?> getTargetExamDate() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyTargetExamDate);
    if (str == null || str.isEmpty) return null;
    return DateTime.tryParse(str);
  }

  static Future<void> setTargetExamDate(DateTime? date) async {
    final prefs = await SharedPreferences.getInstance();
    if (date == null) {
      await prefs.remove(_keyTargetExamDate);
    } else {
      await prefs.setString(_keyTargetExamDate, date.toIso8601String());
    }
  }

  // ── Time Attack Mode ──
  static Future<int> getTimeAttackHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyTimeAttackHighScore) ?? 0;
  }

  static Future<bool> saveTimeAttackScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyTimeAttackHighScore) ?? 0;
    if (score > current) {
      await prefs.setInt(_keyTimeAttackHighScore, score);
      return true; // new high score
    }
    return false;
  }

  static Future<int> getTimeAttackGamesToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString(_keyTimeAttackGamesPlayedDate) ?? '';
    if (savedDate != today) {
      await prefs.setString(_keyTimeAttackGamesPlayedDate, today);
      await prefs.setInt(_keyTimeAttackGamesCount, 0);
      return 0;
    }
    return prefs.getInt(_keyTimeAttackGamesCount) ?? 0;
  }

  static Future<void> incrementTimeAttackGamesToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final count = await getTimeAttackGamesToday();
    await prefs.setString(_keyTimeAttackGamesPlayedDate, today);
    await prefs.setInt(_keyTimeAttackGamesCount, count + 1);
  }

  // ── Onboarding ──
  static Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }

  static Future<void> setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, true);
  }

  // Settings
  static Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyThemeMode) ?? true; // Default dark
  }

  static Future<void> setDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyThemeMode, isDark);
  }

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage) ?? 'ur'; // Default Roman Urdu / Urdu
  }

  static Future<void> setLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, langCode);
  }

  // ── Active Exam Persistence ──
  static Future<void> saveActiveExamState({
    required List<String> questionIds,
    required Map<String, bool> userAnswers,
    required int secondsRemaining,
    required Set<String> flaggedIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'questionIds': questionIds,
      'userAnswers': userAnswers,
      'secondsRemaining': secondsRemaining,
      'flaggedIds': flaggedIds.toList(),
      'savedAt': DateTime.now().millisecondsSinceEpoch,
    };
    await prefs.setString(_keyActiveExam, json.encode(data));
  }

  static Future<Map<String, dynamic>?> getActiveExamState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyActiveExam);
    if (raw == null || raw.isEmpty) return null;
    try {
      return json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearActiveExamState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActiveExam);
  }

  // ── Error Bank 2-Correct Answers Removal ──
  static Future<bool> recordErrorQuestionSuccess(String qId) async {
    final prefs = await SharedPreferences.getInstance();
    final streakKey = '$_keyErrorStreakPrefix$qId';
    final currentStreak = (prefs.getInt(streakKey) ?? 0) + 1;
    if (currentStreak >= 2) {
      await removeErrorQuestionId(qId);
      await prefs.remove(streakKey);
      return true; // Successfully removed from error bank
    } else {
      await prefs.setInt(streakKey, currentStreak);
      return false;
    }
  }

  static Future<void> recordErrorQuestionFailure(String qId) async {
    final prefs = await SharedPreferences.getInstance();
    final streakKey = '$_keyErrorStreakPrefix$qId';
    await prefs.setInt(streakKey, 0); // Reset consecutive streak
  }
}
