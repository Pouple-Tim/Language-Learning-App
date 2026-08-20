import 'package:json_annotation/json_annotation.dart';

part 'word.g.dart';

@JsonSerializable()
class Word {
  final String id;
  final String prompt;   // Le mot à afficher (ex: "あ")
  final String answer;   // La réponse attendue (ex: "a")
  bool removed;          // Si le mot a été réussi aujourd'hui

  Word({
    required this.id,
    required this.prompt,
    required this.answer,
    this.removed = false,
  });

  // Créer une copie avec modifications
  Word copyWith({
    String? id,
    String? prompt,
    String? answer,
    bool? removed,
  }) {
    return Word(
      id: id ?? this.id,
      prompt: prompt ?? this.prompt,
      answer: answer ?? this.answer,
      removed: removed ?? this.removed,
    );
  }

  // JSON Serialization
  factory Word.fromJson(Map<String, dynamic> json) => _$WordFromJson(json);
  Map<String, dynamic> toJson() => _$WordToJson(this);

  @override
  String toString() => 'Word(id: $id, prompt: $prompt, answer: $answer, removed: $removed)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Word &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
