class Question {
  final String id;
  final String topicId;
  final String questionIt;
  final String questionUr;
  final String questionEn;
  final bool isTrue;
  final String explanationIt;
  final String explanationUr;
  final String explanationEn;
  final String? imageUrl;

  Question({
    required this.id,
    required this.topicId,
    required this.questionIt,
    required this.questionUr,
    required this.questionEn,
    required this.isTrue,
    required this.explanationIt,
    required this.explanationUr,
    required this.explanationEn,
    this.imageUrl,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? '',
      topicId: json['topicId'] ?? '',
      questionIt: json['question_it'] ?? '',
      questionUr: json['question_ur'] ?? '',
      questionEn: json['question_en'] ?? '',
      isTrue: json['isTrue'] is bool
          ? json['isTrue'] as bool
          : (json['isTrue'] != null && json['isTrue'].toString().toLowerCase() == 'true'),
      explanationIt: json['explanation_it'] ?? '',
      explanationUr: json['explanation_ur'] ?? '',
      explanationEn: json['explanation_en'] ?? '',
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topicId': topicId,
      'question_it': questionIt,
      'question_ur': questionUr,
      'question_en': questionEn,
      'isTrue': isTrue,
      'explanation_it': explanationIt,
      'explanation_ur': explanationUr,
      'explanation_en': explanationEn,
      'imageUrl': imageUrl,
    };
  }
}
