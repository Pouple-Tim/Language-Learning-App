import 'package:json_annotation/json_annotation.dart';

part 'deck_manifest.g.dart';

@JsonSerializable()
class DeckManifest {
  final String version;
  final String lastUpdate;
  final List<DeckEntry> decks;

  DeckManifest({
    required this.version,
    required this.lastUpdate,
    required this.decks,
  });

  factory DeckManifest.fromJson(Map<String, dynamic> json) =>
      _$DeckManifestFromJson(json);
  Map<String, dynamic> toJson() => _$DeckManifestToJson(this);
}

@JsonSerializable()
class DeckEntry {
  final String path;
  final List<String> categories; // 👈 Hiérarchie de catégories
  
  @JsonKey(defaultValue: 'beginner')
  final String difficulty;
  

  DeckEntry({
    required this.path,
    required this.categories,
    this.difficulty = 'beginner',
  });

  // Helpers pour compatibilité
  String get category => categories.isNotEmpty ? categories.first : 'Autres';
  String get subcategory => categories.length > 1 ? categories.sublist(1).join(' > ') : category;

  factory DeckEntry.fromJson(Map<String, dynamic> json) =>
      _$DeckEntryFromJson(json);
  Map<String, dynamic> toJson() => _$DeckEntryToJson(this);
}