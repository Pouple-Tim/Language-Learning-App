// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sentence.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Sentence _$SentenceFromJson(Map<String, dynamic> json) => Sentence(
  id: json['id'] as String,
  original: json['original'] as String,
  translation: json['translation'] as String,
  blocks: (json['blocks'] as List<dynamic>).map((e) => e as String).toList(),
  completed: json['completed'] as bool? ?? false,
);

Map<String, dynamic> _$SentenceToJson(Sentence instance) => <String, dynamic>{
  'id': instance.id,
  'original': instance.original,
  'translation': instance.translation,
  'blocks': instance.blocks,
  'completed': instance.completed,
};
