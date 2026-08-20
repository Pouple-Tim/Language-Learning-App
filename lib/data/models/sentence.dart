class Sentence {
  final String id;
  final String original;
  final String translation;
  final List<String> blocks;
  
  bool completed; 

  Sentence({
    required this.id,
    required this.original,
    required this.translation,
    required this.blocks,
    this.completed = false,
  });

  factory Sentence.fromJson(Map<String, dynamic> json) {
    return Sentence(
      id: json['id'] ?? '',
      original: json['original'] ?? '',
      translation: json['translation'] ?? '',
      blocks: List<String>.from(json['blocks'] ?? []),
      completed: json['completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'original': original,
      'translation': translation,
      'blocks': blocks,
      'completed': completed,
    };
  }
}