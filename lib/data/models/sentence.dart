import 'package:json_annotation/json_annotation.dart';

part 'sentence.g.dart';

@JsonSerializable()
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

  factory Sentence.fromJson(Map<String, dynamic> json) => _$SentenceFromJson(json);
  Map<String, dynamic> toJson() => _$SentenceToJson(this);
}
