// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Settings _$SettingsFromJson(Map<String, dynamic> json) => Settings(
  isDarkMode: json['isDarkMode'] as bool? ?? false,
  currentDeckId: json['currentDeckId'] as String,
  lastReset: Settings._dateTimeFromJson(json['lastReset'] as String),
);

Map<String, dynamic> _$SettingsToJson(Settings instance) => <String, dynamic>{
  'isDarkMode': instance.isDarkMode,
  'currentDeckId': instance.currentDeckId,
  'lastReset': Settings._dateTimeToJson(instance.lastReset),
};
