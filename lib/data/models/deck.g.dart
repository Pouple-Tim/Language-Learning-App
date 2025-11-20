// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deck.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Deck _$DeckFromJson(Map<String, dynamic> json) => Deck(
  id: json['id'] as String,
  name: json['name'] as String,
  type: $enumDecode(
    _$DeckTypeEnumMap,
    json['type'],
    unknownValue: DeckType.base,
  ),
  inputType: $enumDecode(
    _$InputTypeEnumMap,
    json['inputType'],
    unknownValue: InputType.text,
  ),
  words: (json['words'] as List<dynamic>)
      .map((e) => Word.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DeckToJson(Deck instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': _$DeckTypeEnumMap[instance.type]!,
  'inputType': _$InputTypeEnumMap[instance.inputType]!,
  'words': instance.words,
};

const _$DeckTypeEnumMap = {DeckType.base: 'base', DeckType.custom: 'custom'};

const _$InputTypeEnumMap = {InputType.text: 'text', InputType.draw: 'draw'};
