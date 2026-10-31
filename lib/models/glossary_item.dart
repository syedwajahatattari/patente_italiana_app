class GlossaryItem {
  final String id;
  final String termIt;
  final String termUr;
  final String termEn;
  final String definitionIt;
  final String definitionUr;
  final String category;
  final String exampleIt;

  GlossaryItem({
    required this.id,
    required this.termIt,
    required this.termUr,
    required this.termEn,
    required this.definitionIt,
    required this.definitionUr,
    required this.category,
    required this.exampleIt,
  });

  factory GlossaryItem.fromJson(Map<String, dynamic> json) {
    return GlossaryItem(
      id: json['id'] ?? '',
      termIt: json['term_it'] ?? '',
      termUr: json['term_ur'] ?? '',
      termEn: json['term_en'] ?? '',
      definitionIt: json['definition_it'] ?? '',
      definitionUr: json['definition_ur'] ?? '',
      category: json['category'] ?? 'Generale',
      exampleIt: json['example_it'] ?? '',
    );
  }
}
