import 'package:flutter_test/flutter_test.dart';
import 'package:language_learning_app/data/models/settings.dart';

void main() {
  group('Settings Model Tests', () {
    test('Default Settings Factory', () {
      final settings = Settings.defaultSettings();
      
      expect(settings.isDarkMode, isFalse);
      expect(settings.currentDeckId, 'japanese_hiragana_base');
      // On vérifie que la date est proche de maintenant
      expect(
        settings.lastReset.difference(DateTime.now()).inSeconds.abs(), 
        lessThan(5)
      );
    });

    test('DateTime JSON Serialization', () {
      final date = DateTime(2023, 10, 25, 14, 30);
      final settings = Settings(
        isDarkMode: true, 
        currentDeckId: 'abc', 
        lastReset: date
      );

      final json = settings.toJson();
      expect(json['lastReset'], date.toIso8601String());

      final fromJson = Settings.fromJson(json);
      expect(fromJson.lastReset, date);
      expect(fromJson.isDarkMode, true);
    });

    test('copyWith functionality', () {
      final settings = Settings.defaultSettings();
      
      final newDate = DateTime(2025, 1, 1);
      final updated = settings.copyWith(
        isDarkMode: true,
        lastReset: newDate
      );

      expect(updated.isDarkMode, isTrue);
      expect(updated.lastReset, newDate);
      expect(updated.currentDeckId, settings.currentDeckId); // Inchangé
    });
  });
}