import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/question.dart';
import '../models/topic.dart';
import '../models/glossary_item.dart';
import '../models/exam_result.dart';
import '../services/storage_service.dart';

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

  // Active Exam State
  List<Question> _activeExamQuestions = [];
  Map<String, bool?> _userAnswers = {}; // questionId -> true(Vero)/false(Falso)/null
  Set<String> _flaggedQuestionIds = {};
  int _currentQuestionIndex = 0;
  int _timerSecondsRemaining = 1200; // 20 minutes countdown
  Timer? _examTimer;
  bool _isExamCompleted = false;
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
  int get timerSecondsRemaining => _timerSecondsRemaining;
  bool get isExamCompleted => _isExamCompleted;
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

    // Count errors per topic from all exam history
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

    // Find topic with highest error rate (min 3 attempts)
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
    } catch (e) {
      debugPrint("Error loading quiz JSON datasets: $e");
      _hasError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Start Standard Ministerial Exam (Scheda Esame)
  // Official rule: 30 questions distributed across the syllabus topics
  void startMinisterialExam() {
    _examTimer?.cancel();
    
    // Group questions by topic
    final Map<String, List<Question>> byTopic = {};
    for (var q in _allQuestions) {
      byTopic.putIfAbsent(q.topicId, () => []).add(q);
    }
    
    List<Question> selected = [];
    // Pick 1 question from each available topic
    for (var topicQuestions in byTopic.values) {
      if (topicQuestions.isNotEmpty) {
        final shuffled = List<Question>.from(topicQuestions)..shuffle();
        selected.add(shuffled.first);
      }
    }
    
    // If fewer than 30, pick remaining from high-frequency core topics
    if (selected.length < 30) {
      final remaining = List<Question>.from(_allQuestions)
        ..removeWhere((q) => selected.contains(q))
        ..shuffle();
      selected.addAll(remaining.take(30 - selected.length));
    } else if (selected.length > 30) {
      selected.shuffle();
      selected = selected.sublist(0, 30);
    }
    
    selected.shuffle();
    _activeExamQuestions = selected;
    _userAnswers = {};
    _flaggedQuestionIds = {};
    _currentQuestionIndex = 0;
    _timerSecondsRemaining = 1200; // 20 mins
    _isExamCompleted = false;

    _startTimer();
    notifyListeners();
  }

  // Start Topic Practice Quiz
  void startTopicQuiz(String topicId) {
    _examTimer?.cancel();
    _activeExamQuestions = _allQuestions.where((q) => q.topicId == topicId).toList()..shuffle();
    if (_activeExamQuestions.isEmpty) {
      _activeExamQuestions = List.from(_allQuestions)..shuffle();
    }
    _userAnswers = {};
    _flaggedQuestionIds = {};
    _currentQuestionIndex = 0;
    _timerSecondsRemaining = 1800; // 30 mins
    _isExamCompleted = false;

    _startTimer();
    notifyListeners();
  }

  // Start Error Bank Quiz
  void startErrorBankQuiz() {
    _examTimer?.cancel();
    _activeExamQuestions = List.from(errorBankQuestions)..shuffle();
    if (_activeExamQuestions.isEmpty) {
      _activeExamQuestions = List.from(_allQuestions)..shuffle();
    }
    _userAnswers = {};
    _flaggedQuestionIds = {};
    _currentQuestionIndex = 0;
    _timerSecondsRemaining = 1200;
    _isExamCompleted = false;

    _startTimer();
    notifyListeners();
  }

  // Start "Domande Impossibili" / Trap Quiz (Top hard/misleading questions)
  void startDifficultQuiz() {
    _examTimer?.cancel();
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
    }).toList();

    filtered.shuffle();
    _activeExamQuestions = (filtered.length >= 30 ? filtered.sublist(0, 30) : filtered);
    if (_activeExamQuestions.isEmpty) {
      _activeExamQuestions = List.from(_allQuestions)..shuffle();
      if (_activeExamQuestions.length > 30) {
        _activeExamQuestions = _activeExamQuestions.sublist(0, 30);
      }
    }

    _userAnswers = {};
    _flaggedQuestionIds = {};
    _currentQuestionIndex = 0;
    _timerSecondsRemaining = 1200; // 20 mins
    _isExamCompleted = false;

    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _examTimer?.cancel();
    _examTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSecondsRemaining > 0) {
        _timerSecondsRemaining--;
        notifyListeners();
      } else {
        submitExam();
      }
    });
  }

  void stopTimer() {
    _examTimer?.cancel();
  }

  void answerCurrentQuestion(bool answer) {
    if (_activeExamQuestions.isEmpty) return;
    final currentQ = _activeExamQuestions[_currentQuestionIndex];
    _userAnswers[currentQ.id] = answer;
    notifyListeners();
  }

  void toggleFlagCurrentQuestion() {
    if (_activeExamQuestions.isEmpty) return;
    final currentQId = _activeExamQuestions[_currentQuestionIndex].id;
    if (_flaggedQuestionIds.contains(currentQId)) {
      _flaggedQuestionIds.remove(currentQId);
    } else {
      _flaggedQuestionIds.add(currentQId);
    }
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

  Future<void> submitExam() async {
    _examTimer?.cancel();
    _isExamCompleted = true;

    int correctCount = 0;
    int errorCount = 0;

    for (var q in _activeExamQuestions) {
      final userAns = _userAnswers[q.id];
      if (userAns != null && userAns == q.isTrue) {
        correctCount++;
      } else {
        errorCount++;
        // BUG FIX: Only add to error bank if user actually answered wrong, NOT if unanswered
        if (userAns != null) {
          await StorageService.addErrorQuestionId(q.id);
          _errorQuestionIds.add(q.id);
        }
      }
    }

    final bool passed = errorCount <= 3;

    _lastExamResult = ExamResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      totalQuestions: _activeExamQuestions.length,
      correctAnswers: correctCount,
      errors: errorCount,
      timeSpentSeconds: 1200 - _timerSecondsRemaining,
      isPassed: passed,
      userAnswers: Map.from(_userAnswers),
    );

    await StorageService.saveExamResult(_lastExamResult!);
    _examResults.insert(0, _lastExamResult!);

    // Update streak & daily stats
    _dailyStreak = await StorageService.incrementStreak();
    await StorageService.addTodayQuestionsPracticed(_activeExamQuestions.length);
    _todayQuestionsPracticed = await StorageService.getTodayQuestionsPracticed();

    notifyListeners();
  }

  @override
  void dispose() {
    _examTimer?.cancel();
    super.dispose();
  }
}
