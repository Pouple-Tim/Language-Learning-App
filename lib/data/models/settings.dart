import 'package:json_annotation/json_annotation.dart';

part 'settings.g.dart';

@JsonSerializable()
class Settings {
  bool isDarkMode;
  String currentDeckId;
  
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  DateTime lastReset;

  Settings({
    this.isDarkMode = false,
    required this.currentDeckId,
    required this.lastReset,
  });

  // Créer des settings par défaut
  factory Settings.defaultSettings() {
    return Settings(
      isDarkMode: false,
      currentDeckId: 'japanese_hiragana_base',
      lastReset: DateTime.now(),
    );
  }

  // Créer une copie avec modifications
  Settings copyWith({
    bool? isDarkMode,
    String? currentDeckId,
    DateTime? lastReset,
  }) {
    return Settings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      currentDeckId: currentDeckId ?? this.currentDeckId,
      lastReset: lastReset ?? this.lastReset,
    );
  }

  // JSON Serialization
  factory Settings.fromJson(Map<String, dynamic> json) => _$SettingsFromJson(json);
  Map<String, dynamic> toJson() => _$SettingsToJson(this);

  // Helper pour DateTime
  static DateTime _dateTimeFromJson(String date) => DateTime.parse(date);
  static String _dateTimeToJson(DateTime date) => date.toIso8601String();

  @override
  String toString() => 'Settings(darkMode: $isDarkMode, deck: $currentDeckId)';
}