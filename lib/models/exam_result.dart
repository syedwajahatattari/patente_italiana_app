class ExamResult {
  final String id;
  final DateTime date;
  final int totalQuestions;
  final int correctAnswers;
  final int errors;
  final int timeSpentSeconds;
  final bool isPassed; // true if errors <= 3
  final Map<String, bool?> userAnswers; // questionId -> answer (true/false)

  ExamResult({
    required this.id,
    required this.date,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.errors,
    required this.timeSpentSeconds,
    required this.isPassed,
    required this.userAnswers,
  });

  factory ExamResult.fromJson(Map<String, dynamic> json) {
    return ExamResult(
      id: json['id'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      totalQuestions: json['totalQuestions'] ?? 30,
      correctAnswers: json['correctAnswers'] ?? 0,
      errors: json['errors'] ?? 0,
      timeSpentSeconds: json['timeSpentSeconds'] ?? 0,
      isPassed: json['isPassed'] ?? false,
      userAnswers: Map<String, bool?>.from(json['userAnswers'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'errors': errors,
      'timeSpentSeconds': timeSpentSeconds,
      'isPassed': isPassed,
      'userAnswers': userAnswers,
    };
  }
}
