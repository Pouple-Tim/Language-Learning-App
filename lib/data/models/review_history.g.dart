// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewEntry _$ReviewEntryFromJson(Map<String, dynamic> json) => ReviewEntry(
  wordId: json['wordId'] as String,
  deckId: json['deckId'] as String,
  reviewedAt: DateTime.parse(json['reviewedAt'] as String),
  wasCorrect: json['wasCorrect'] as bool,
  inputType: json['inputType'] as String,
  gameMode: json['gameMode'] as String?,
);

Map<String, dynamic> _$ReviewEntryToJson(ReviewEntry instance) =>
    <String, dynamic>{
      'wordId': instance.wordId,
      'deckId': instance.deckId,
      'reviewedAt': instance.reviewedAt.toIso8601String(),
      'wasCorrect': instance.wasCorrect,
      'inputType': instance.inputType,
      'gameMode': instance.gameMode,
    };

ReviewHistory _$ReviewHistoryFromJson(Map<String, dynamic> json) =>
    ReviewHistory(
      entries: (json['entries'] as List<dynamic>)
          .map((e) => ReviewEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ReviewHistoryToJson(ReviewHistory instance) =>
    <String, dynamic>{'entries': instance.entries};
