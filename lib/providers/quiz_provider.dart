import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/question.dart';
import '../models/topic.dart';
import '../models/glossary_item.dart';
import '../models/exam_result.dart';
import '../services/storage_service.dart';
import 'subscription_provider.dart';

enum QuizMode { exam, topic, errorBank, difficult }

class QuizProvider extends ChangeNotifier {
  List<Question> _allQuestions = [];
  List<Topic> _topics = [];
  List<GlossaryItem> _glossaryItems = [];
  List<ExamResult> _examResults = [];
  Set<String> _errorQuestionIds = {};

  bool _isLoading = true;
  bool _hasError = false;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  List<Question> get allQuestions => _allQuestions;
  List<Topic> get topics => _topics;
  List<GlossaryItem> get glossaryItems => _glossaryItems;
  List<ExamResult> get examResults => _examResults;

  // Active Exam / Practice State
  QuizMode _quizMode = QuizMode.exam;
  QuizMode get quizMode => _quizMode;

  List<Question> _activeExamQuestions = [];
  Map<String, bool?> _userAnswers = {}; // questionId -> true(Vero)/false(Falso)/null
  Set<String> _flaggedQuestionIds = {};
  int _currentQuestionIndex = 0;
  int _quizInitialSeconds = 1200; // 20 mins for exam, 30 for practice
  int _timerSecondsRemaining = 1200;
  Timer? _examTimer;
  bool _isExamCompleted = false;
  bool _isTimerPaused = false;
  bool _isAutoSubmitted = false;
  ExamResult? _lastExamResult;

  // Streak & Engagement
  int _dailyStreak = 0;
  int _todayQuestionsPracticed = 0;
  DateTime? _targetExamDate;
  final int dailyTargetQuestions = 30;

  List<Question> get activeExamQuestions => _activeExamQuestions;
  Map<String, bool?> get userAnswers => _userAnswers;
  Set<String> get flaggedQuestionIds => _flaggedQuestionIds;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get quizInitialSeconds => _quizInitialSeconds;
  int get timerSecondsRemaining => _timerSecondsRemaining;
  bool get isExamCompleted => _isExamCompleted;
  bool get isTimerPaused => _isTimerPaused;
  bool get isAutoSubmitted => _isAutoSubmitted;
  ExamResult? get lastExamResult => _lastExamResult;
  int get dailyStreak => _dailyStreak;
  int get todayQuestionsPracticed => _todayQuestionsPracticed;
  DateTime? get targetExamDate => _targetExamDate;

  int? get daysUntilExam {
    if (_targetExamDate == null) return null;
    final now = DateTime.now();
    final diff = _targetExamDate!.difference(DateTime(now.year, now.month, now.day)).inDays;
    return diff < 0 ? 0 : diff;
  }

  double get dailyTargetProgress {
    if (dailyTargetQuestions <= 0) return 1.0;
    return (_todayQuestionsPracticed / dailyTargetQuestions).clamp(0.0, 1.0);
  }

  Future<void> setTargetExamDate(DateTime? date) async {
    _targetExamDate = date;
    await StorageService.setTargetExamDate(date);
    notifyListeners();
  }

  // Error Bank Questions
  List<Question> get errorBankQuestions =>
      _allQuestions.where((q) => _errorQuestionIds.contains(q.id)).toList();

  void removeErrorQuestion(String qId) {
    _errorQuestionIds.remove(qId);
    notifyListeners();
  }

  // Statistics
  int get totalExamsTaken => _examResults.length;
  int get passedExamsCount => _examResults.where((r) => r.isPassed).length;
  double? get passProbability {
    if (_examResults.isEmpty) return null;
    double passRate = (passedExamsCount / totalExamsTaken) * 100;
    return passRate.clamp(5.0, 99.0);
  }

  double get averageErrorsPerExam {
    if (_examResults.isEmpty) return 0;
    final totalErrors = _examResults.fold<int>(0, (sum, r) => sum + r.errors);
    return totalErrors / _examResults.length;
  }

  double get averageTimePerExam {
    if (_examResults.isEmpty) return 0;
    final totalTime = _examResults.fold<int>(0, (sum, r) => sum + r.timeSpentSeconds);
    return totalTime / _examResults.length;
  }

  /// Returns the topic with the worst accuracy (most errors)
  Map<String, dynamic>? get weakestTopic {
    if (_examResults.isEmpty || _allQuestions.isEmpty || _topics.isEmpty) return null;

    final Map<String, int> topicErrors = {};
    final Map<String, int> topicAttempts = {};

    for (var result in _examResults) {
      for (var entry in result.userAnswers.entries) {
        final question = _allQuestions.where((q) => q.id == entry.key).firstOrNull;
        if (question != null) {
          topicAttempts[question.topicId] = (topicAttempts[question.topicId] ?? 0) + 1;
          if (entry.value != question.isTrue) {
            topicErrors[question.topicId] = (topicErrors[question.topicId] ?? 0) + 1;
          }
        }
      }
    }

    if (topicErrors.isEmpty) return null;

    String? worstTopicId;
    double worstRate = 0;
    for (var topicId in topicErrors.keys) {
      final attempts = topicAttempts[topicId] ?? 1;
      if (attempts < 3) continue;
      final rate = (topicErrors[topicId] ?? 0) / attempts;
      if (rate > worstRate) {
        worstRate = rate;
        worstTopicId = topicId;
      }
    }

    if (worstTopicId == null) return null;

    final topic = _topics.where((t) => t.id == worstTopicId).firstOrNull;
    if (topic == null) return null;

    return {
      'topic': topic,
      'errorRate': (worstRate * 100).round(),
      'errors': topicErrors[worstTopicId],
      'attempts': topicAttempts[worstTopicId],
    };
  }

  QuizProvider() {
    initData();
  }

  Future<void> initData() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      // 1. Load Topics
      final String topicsJsonStr = await rootBundle.loadString('assets/data/topics.json');
      final List<dynamic> topicsRaw = json.decode(topicsJsonStr);
      _topics = topicsRaw.map((t) => Topic.fromJson(t)).toList();

      // 2. Load Glossary
      final String glossaryJsonStr = await rootBundle.loadString('assets/data/glossary.json');
      final List<dynamic> glossaryRaw = json.decode(glossaryJsonStr);
      _glossaryItems = glossaryRaw.map((g) => GlossaryItem.fromJson(g)).toList();

      // 3. Load Questions
      final String questionsJsonStr = await rootBundle.loadString('assets/data/quiz_questions.json');
      final List<dynamic> questionsRaw = json.decode(questionsJsonStr);
      _allQuestions = questionsRaw.map((q) => Question.fromJson(q)).toList();

      // 4. Load Saved History & Error Bank from SharedPreferences
      _examResults = await StorageService.getExamResults();
      _errorQuestionIds = await StorageService.getErrorBankQuestionIds();

      // 5. Load streak & engagement data
      final streakData = await StorageService.getStreakData();
      _dailyStreak = streakData['streak'] ?? 0;
      _todayQuestionsPracticed = await StorageService.getTodayQuestionsPracticed();
      _targetExamDate = await StorageService.getTargetExamDate();

      // 6. Restore active exam if one was in progress when app exited
      await restoreActiveExamIfAny();
    } catch (e) {
      debugPrint("Error loading quiz JSON datasets: $e");
      _hasError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Restore active in-progress exam if user was interrupted
  Future<void> restoreActiveExamIfAny() async {
    final state = await StorageService.getActiveExamState();
    if (state == null) return;

    final qIds = List<String>.from(state['questionIds'] ?? []);
    if (qIds.length != 30) {
      await StorageService.clearActiveExamState();
      return;
    }

    final savedRemaining = state['secondsRemaining'] as int? ?? 1200;
    if (savedRemaining <= 0) {
      await StorageService.clearActiveExamState();
      return;
    }

    final questionsMap = {for (var q in _allQuestions) q.id: q};
    final restoredQuestions = qIds.map((id) => questionsMap[id]).whereType<Question>().toList();
    if (restoredQuestions.length != 30) {
      await StorageService.clearActiveExamState();
      return;
    }

    _activeExamQuestions = restoredQuestions;
    _userAnswers = (state['userAnswers'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, v as bool?));
    _flaggedQuestionIds = Set<String>.from(state['flaggedIds'] ?? []);
    _timerSecondsRemaining = savedRemaining;
    _quizInitialSeconds = 1200;
    _quizMode = QuizMode.exam;
    _isExamCompleted = false;
    _isTimerPaused = true; // start paused so candidate can tap resume
    notifyListeners();
  }

  // ── Ministerial Exam (Scheda Esame) ──
  // 30 unique questions, topic-weighted distribution, balanced to 13–17 VERO / 13–17 FALSO
  void startMinisterialExam() {
    _examTimer?.cancel();
    _quizMode = QuizMode.exam;
    _quizInitialSeconds = 1200; // 20 mins
    _timerSecondsRemaining = 1200;
    _isExamCompleted = false;
    _isTimerPaused = false;
    _isAutoSubmitted = false;

    final random = Random();
    // Balanced Vero / Falso target (14, 15, or 16 VERO)
    final int targetTrue = 14 + random.nextInt(3); // 14 to 16
    final int targetFalse = 30 - targetTrue; // 14 to 16

    // Separate into true/false pools
    final truePool = _allQuestions.where((q) => q.isTrue).toList()..shuffle();
    final falsePool = _allQuestions.where((q) => !q.isTrue).toList()..shuffle();

    // Group by topic to ensure topic coverage
    final Map<String, List<Question>> trueByTopic = {};
    for (var q in truePool) {
      trueByTopic.putIfAbsent(q.topicId, () => []).add(q);
    }

    final Map<String, List<Question>> falseByTopic = {};
    for (var q in falsePool) {
      falseByTopic.putIfAbsent(q.topicId, () => []).add(q);
    }

    final List<Question> selected = [];
    final Set<String> selectedIds = {};

    // 1. Pick 1 True from each topic as available until targetTrue reached
    for (var topicList in trueByTopic.values) {
      if (selected.where((q) => q.isTrue).length >= targetTrue) break;
      for (var q in topicList) {
        if (!selectedIds.contains(q.id)) {
          selected.add(q);
          selectedIds.add(q.id);
          break;
        }
      }
    }

    // Fill remaining True if needed
    for (var q in truePool) {
      if (selected.where((s) => s.isTrue).length >= targetTrue) break;
      if (!selectedIds.contains(q.id)) {
        selected.add(q);
        selectedIds.add(q.id);
      }
    }

    // 2. Pick 1 False from each topic as available until targetFalse reached
    for (var topicList in falseByTopic.values) {
      if (selected.where((q) => !q.isTrue).length >= targetFalse) break;
      for (var q in topicList) {
        if (!selectedIds.contains(q.id)) {
          selected.add(q);
          selectedIds.add(q.id);
          break;
        }
      }
    }

    // Fill remaining False if needed
    for (var q in falsePool) {
      if (selected.where((s) => !s.isTrue).length >= targetFalse) break;
      if (!selectedIds.contains(q.id)) {
        selected.add(q);
        selectedIds.add(q.id);
      }
    }

    selected.shuffle();
    _activeExamQuestions = selected;
    _userAnswers = {};
    _flaggedQuestionIds = {};
    _currentQuestionIndex = 0;

    _persistActiveExam();
    _startTimer();
    notifyListeners();
  }

  // ── Start Topic Practice Quiz (Capped at 30 questions) ──
  void startTopicQuiz(String topicId) {
    _examTimer?.cancel();
    _quizMode = QuizMode.topic;
    _quizInitialSeconds = 1800; // 30 mins for practice
    _timerSecondsRemaining = 1800;
    _isExamCompleted = false;
    _isTimerPaused = false;
    _isAutoSubmitted = false;

    final topicQuestions = _allQuestions.where((q) => q.topicId == topicId).toList()..shuffle();
    // Cap to 30 questions for focused practice
    _activeExamQuestions = topicQuestions.length > 30 ? topicQuestions.sublist(0, 30) : topicQuestions;

    _userAnswers = {};
    _flaggedQuestionIds = {};
    _currentQuestionIndex = 0;

    _startTimer();
    notifyListeners();
  }

  // ── Start Error Bank Quiz (Capped at 30 questions, no fallback to all) ──
  void startErrorBankQuiz() {
    _examTimer?.cancel();
    _quizMode = QuizMode.errorBank;
    _quizInitialSeconds = 1200;
    _timerSecondsRemaining = 1200;
    _isExamCompleted = false;
    _isTimerPaused = false;
    _isAutoSubmitted = false;

    final errQuestions = List<Question>.from(errorBankQuestions)..shuffle();
    // Cap to 30, but DO NOT fallback to all questions if empty
    _activeExamQuestions = errQuestions.length > 30 ? errQuestions.sublist(0, 30) : errQuestions;

    _userAnswers = {};
    _flaggedQuestionIds = {};
    _currentQuestionIndex = 0;

    _startTimer();
    notifyListeners();
  }

  // ── Start Trap Quiz (Domande Impossibili) ──
  void startDifficultQuiz() {
    _examTimer?.cancel();
    _quizMode = QuizMode.difficult;
    _quizInitialSeconds = 1200;
    _timerSecondsRemaining = 1200;
    _isExamCompleted = false;
    _isTimerPaused = false;
    _isAutoSubmitted = false;

    final trapKeywords = [
      'esclusivamente',
      'soltanto',
      'in ogni caso',
      'obbligatoriamente',
      'mai',
      'qualsiasi',
      'tassativamente',
      'sempre',
      'precedenza',
      'sorpasso'
    ];

    final filtered = _allQuestions.where((q) {
      final text = q.questionIt.toLowerCase();
      return trapKeywords.any((kw) => text.contains(kw));
    }).toList()..shuffle();

    _activeExamQuestions = filtered.length > 30 ? filtered.sublist(0, 30) : filtered;
    _userAnswers = {};
    _flaggedQuestionIds = {};
    _currentQuestionIndex = 0;

    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _examTimer?.cancel();
    _examTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSecondsRemaining > 0) {
        _timerSecondsRemaining--;
        if (_timerSecondsRemaining % 10 == 0) {
          _persistActiveExam();
        }
        notifyListeners();
      } else {
        _timerSecondsRemaining = 0;
        _isAutoSubmitted = true;
        _examTimer?.cancel();
        if (_quizMode == QuizMode.exam) {
          submitExam();
        } else {
          submitPractice();
        }
        notifyListeners();
      }
    });
  }

  void pauseTimer() {
    if (_examTimer != null && _examTimer!.isActive) {
      _examTimer?.cancel();
      _isTimerPaused = true;
      _persistActiveExam();
      notifyListeners();
    }
  }

  void resumeTimer() {
    if (_isTimerPaused && !_isExamCompleted && _timerSecondsRemaining > 0) {
      _isTimerPaused = false;
      _startTimer();
      notifyListeners();
    }
  }

  void stopTimer() {
    _examTimer?.cancel();
    _isTimerPaused = false;
  }

  void clearAutoSubmitted() {
    _isAutoSubmitted = false;
  }

  void _persistActiveExam() {
    if (_quizMode == QuizMode.exam && !_isExamCompleted && _activeExamQuestions.isNotEmpty) {
      StorageService.saveActiveExamState(
        questionIds: _activeExamQuestions.map((q) => q.id).toList(),
        userAnswers: _userAnswers.map((k, v) => MapEntry(k, v ?? false)),
        secondsRemaining: _timerSecondsRemaining,
        flaggedIds: _flaggedQuestionIds,
      );
    }
  }

  void answerCurrentQuestion(bool answer) {
    if (_activeExamQuestions.isEmpty || _isExamCompleted) return;
    final currentQ = _activeExamQuestions[_currentQuestionIndex];
    _userAnswers[currentQ.id] = answer;
    _persistActiveExam();
    notifyListeners();
  }

  void toggleFlagCurrentQuestion() {
    if (_activeExamQuestions.isEmpty || _isExamCompleted) return;
    final currentQId = _activeExamQuestions[_currentQuestionIndex].id;
    if (_flaggedQuestionIds.contains(currentQId)) {
      _flaggedQuestionIds.remove(currentQId);
    } else {
      _flaggedQuestionIds.add(currentQId);
    }
    _persistActiveExam();
    notifyListeners();
  }

  void goToQuestion(int index) {
    if (index >= 0 && index < _activeExamQuestions.length) {
      _currentQuestionIndex = index;
      notifyListeners();
    }
  }

  void nextQuestion() {
    if (_currentQuestionIndex < _activeExamQuestions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  /// Official Ministerial Exam Submission.
  /// Deducts daily attempt only on submit (not start), prevents double counting,
  /// computes time spent from initial seconds, removes questions answered correctly twice.
  Future<void> submitExam({SubscriptionProvider? subProvider}) async {
    if (_isExamCompleted) return; // Guard against double submit
    _examTimer?.cancel();
    _isExamCompleted = true;
    _isTimerPaused = false;
    await StorageService.clearActiveExamState();

    int correctCount = 0;
    int errorCount = 0;

    for (var q in _activeExamQuestions) {
      final userAns = _userAnswers[q.id];
      if (userAns != null && userAns == q.isTrue) {
        correctCount++;
        // P0-5: consecutive correct answers removes question from error bank!
        if (_errorQuestionIds.contains(q.id)) {
          final removed = await StorageService.recordErrorQuestionSuccess(q.id);
          if (removed) {
            _errorQuestionIds.remove(q.id);
          }
        }
      } else {
        errorCount++;
        // Only add to error bank if user explicitly answered incorrectly
        if (userAns != null) {
          await StorageService.addErrorQuestionId(q.id);
          _errorQuestionIds.add(q.id);
          await StorageService.recordErrorQuestionFailure(q.id);
        }
      }
    }

    final bool passed = errorCount <= 3;
    final int timeSpent = (_quizInitialSeconds - _timerSecondsRemaining).clamp(0, _quizInitialSeconds);

    _lastExamResult = ExamResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      totalQuestions: _activeExamQuestions.length,
      correctAnswers: correctCount,
      errors: errorCount,
      timeSpentSeconds: timeSpent,
      isPassed: passed,
      userAnswers: Map.from(_userAnswers),
    );

    await StorageService.saveExamResult(_lastExamResult!);
    _examResults.insert(0, _lastExamResult!);

    // P1-10: Record daily attempt on submit, NOT on start!
    if (subProvider != null) {
      await subProvider.recordExamAttempt();
    }

    // Update streak & daily stats
    _dailyStreak = await StorageService.incrementStreak();
    await StorageService.addTodayQuestionsPracticed(_activeExamQuestions.length);
    _todayQuestionsPracticed = await StorageService.getTodayQuestionsPracticed();

    notifyListeners();
  }

  /// Practice submission for Topic / Error Bank / Difficult Quizzes.
  /// Does NOT create an ExamResult or pollute exam history/pass rate.
  Future<void> submitPractice() async {
    if (_isExamCompleted) return;
    _examTimer?.cancel();
    _isExamCompleted = true;
    _isTimerPaused = false;
    await StorageService.clearActiveExamState();

    for (var q in _activeExamQuestions) {
      final userAns = _userAnswers[q.id];
      if (userAns != null && userAns == q.isTrue) {
        if (_errorQuestionIds.contains(q.id)) {
          final removed = await StorageService.recordErrorQuestionSuccess(q.id);
          if (removed) {
            _errorQuestionIds.remove(q.id);
          }
        }
      } else if (userAns != null) {
        await StorageService.addErrorQuestionId(q.id);
        _errorQuestionIds.add(q.id);
        await StorageService.recordErrorQuestionFailure(q.id);
      }
    }

    if (_userAnswers.isNotEmpty) {
      await StorageService.addTodayQuestionsPracticed(_userAnswers.length);
      _todayQuestionsPracticed = await StorageService.getTodayQuestionsPracticed();
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _examTimer?.cancel();
    super.dispose();
  }
}
