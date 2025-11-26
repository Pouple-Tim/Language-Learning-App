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
  final InputType inputType; // Input pour le mode Classique

  @JsonKey(unknownEnumValue: InputType.text)
  final InputType? reverseInputType; // Input spécifique pour le mode Reverse (Optionnel)
  
  List<Word> words;

  Deck({
    required this.id,
    required this.name,
    required this.type,
    required this.inputType,
    this.reverseInputType, // Nouveau paramètre
    required this.words,
  });

  // Helper : Retourne l'input type pour le reverse, ou 'text' par défaut si null
  InputType get effectiveReverseInputType => reverseInputType ?? InputType.text;

  // Obtenir les mots actifs (non retirés)
  List<Word> get activeWords => words.where((w) => !w.removed).toList();
  
  int get totalWords => words.length;
  
  int get remainingWords => activeWords.length;
  
  double get progress {
    if (totalWords == 0) return 0.0;
    return ((totalWords - remainingWords) / totalWords) * 100;
  }
  
  bool get isCompleted => remainingWords == 0;

  void resetWords() {
    for (var word in words) {
      word.removed = false;
    }
  }

  Deck copyWith({
    String? id,
    String? name,
    DeckType? type,
    InputType? inputType,
    InputType? reverseInputType,
    List<Word>? words,
  }) {
    return Deck(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      inputType: inputType ?? this.inputType,
      reverseInputType: reverseInputType ?? this.reverseInputType,
      words: words ?? this.words,
    );
  }

  factory Deck.fromJson(Map<String, dynamic> json) => _$DeckFromJson(json);
  Map<String, dynamic> toJson() => _$DeckToJson(this);

  @override
  String toString() => 'Deck(id: $id, name: $name, input: $inputType, reverse: $reverseInputType)';
}