class Topic {
  final String id;
  final String titleIt;
  final String titleUr;
  final String titleEn;
  final String icon;
  final String category;
  final int totalQuestions;
  final String descriptionIt;

  Topic({
    required this.id,
    required this.titleIt,
    required this.titleUr,
    required this.titleEn,
    required this.icon,
    required this.category,
    required this.totalQuestions,
    required this.descriptionIt,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'] ?? '',
      titleIt: json['title_it'] ?? '',
      titleUr: json['title_ur'] ?? '',
      titleEn: json['title_en'] ?? '',
      icon: json['icon'] ?? 'book',
      category: json['category'] ?? 'Generale',
      totalQuestions: json['totalQuestions'] ?? 0,
      descriptionIt: json['description_it'] ?? '',
    );
  }
}
