// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deck_manifest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeckManifest _$DeckManifestFromJson(Map<String, dynamic> json) => DeckManifest(
  version: json['version'] as String,
  lastUpdate: json['lastUpdate'] as String,
  decks: (json['decks'] as List<dynamic>)
      .map((e) => DeckEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DeckManifestToJson(DeckManifest instance) =>
    <String, dynamic>{
      'version': instance.version,
      'lastUpdate': instance.lastUpdate,
      'decks': instance.decks,
    };

DeckEntry _$DeckEntryFromJson(Map<String, dynamic> json) => DeckEntry(
  path: json['path'] as String,
  categories: (json['categories'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  difficulty: json['difficulty'] as String? ?? 'beginner',
);

Map<String, dynamic> _$DeckEntryToJson(DeckEntry instance) => <String, dynamic>{
  'path': instance.path,
  'categories': instance.categories,
  'difficulty': instance.difficulty,
};
