// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Word _$WordFromJson(Map<String, dynamic> json) => Word(
  prompt: json['prompt'] as String,
  answer: json['answer'] as String,
  removed: json['removed'] as bool? ?? false,
);

Map<String, dynamic> _$WordToJson(Word instance) => <String, dynamic>{
  'prompt': instance.prompt,
  'answer': instance.answer,
  'removed': instance.removed,
};
