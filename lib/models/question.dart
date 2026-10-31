class Question {
  final String id;
  final String topicId;
  final String questionIt;
  final String questionUr;
  final String questionEn;
  final String questionRomanUrdu;
  final bool isTrue;
  final String explanationIt;
  final String explanationUr;
  final String explanationEn;
  final String explanationRomanUrdu;
  final String? imageUrl;

  Question({
    required this.id,
    required this.topicId,
    required this.questionIt,
    required this.questionUr,
    required this.questionEn,
    this.questionRomanUrdu = '',
    required this.isTrue,
    required this.explanationIt,
    required this.explanationUr,
    required this.explanationEn,
    this.explanationRomanUrdu = '',
    this.imageUrl,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? '',
      topicId: json['topicId'] ?? '',
      questionIt: json['question_it'] ?? '',
      questionUr: json['question_ur'] ?? '',
      questionEn: json['question_en'] ?? '',
      questionRomanUrdu: json['question_roman_urdu'] ?? '',
      isTrue: json['isTrue'] is bool
          ? json['isTrue'] as bool
          : (json['isTrue'] != null && json['isTrue'].toString().toLowerCase() == 'true'),
      explanationIt: json['explanation_it'] ?? '',
      explanationUr: json['explanation_ur'] ?? '',
      explanationEn: json['explanation_en'] ?? '',
      explanationRomanUrdu: json['explanation_roman_urdu'] ?? '',
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
      'question_roman_urdu': questionRomanUrdu,
      'isTrue': isTrue,
      'explanation_it': explanationIt,
      'explanation_ur': explanationUr,
      'explanation_en': explanationEn,
      'explanation_roman_urdu': explanationRomanUrdu,
      'imageUrl': imageUrl,
    };
  }
}
