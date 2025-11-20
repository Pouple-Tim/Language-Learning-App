import 'package:json_annotation/json_annotation.dart';
import 'word.dart';

part 'deck.g.dart';

enum DeckType {
  @JsonValue('base')
  base,
  @JsonValue('custom')
  custom,
}

enum InputType {
  @JsonValue('text')
  text,
  @JsonValue('draw')
  draw,
}

@JsonSerializable()
class Deck {
  final String id;
  final String name;
  
  @JsonKey(unknownEnumValue: DeckType.base)
  final DeckType type;
  
  @JsonKey(unknownEnumValue: InputType.text)
  final InputType inputType;
  
  List<Word> words;

  Deck({
    required this.id,
    required this.name,
    required this.type,
    required this.inputType,
    required this.words,
  });

  // Obtenir les mots actifs (non retirés)
  List<Word> get activeWords => words.where((w) => !w.removed).toList();
  
  // Nombre total de mots
  int get totalWords => words.length;
  
  // Nombre de mots restants
  int get remainingWords => activeWords.length;
  
  // Progression en pourcentage
  double get progress {
    if (totalWords == 0) return 0.0;
    return ((totalWords - remainingWords) / totalWords) * 100;
  }
  
  // Vérifier si le deck est terminé
  bool get isCompleted => remainingWords == 0;

  // Reset tous les mots (enlever le flag "removed")
  void resetWords() {
    for (var word in words) {
      word.removed = false;
    }
  }

  // Créer une copie avec modifications
  Deck copyWith({
    String? id,
    String? name,
    DeckType? type,
    InputType? inputType,
    List<Word>? words,
  }) {
    return Deck(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      inputType: inputType ?? this.inputType,
      words: words ?? this.words,
    );
  }

  // JSON Serialization
  factory Deck.fromJson(Map<String, dynamic> json) => _$DeckFromJson(json);
  Map<String, dynamic> toJson() => _$DeckToJson(this);

  @override
  String toString() => 'Deck(id: $id, name: $name, words: ${words.length})';
}