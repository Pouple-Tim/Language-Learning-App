import 'package:flutter/foundation.dart';
import 'package:language_learning_app/data/models/settings.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';
import 'package:language_learning_app/core/constants/app_constants.dart';

class SettingsRepository {
  // Charger les paramètres
  Future<Settings> loadSettings() async {
    try {
      final json = StorageHelper.getJson(AppConstants.keySettings);
      
      if (json != null) {
        return Settings.fromJson(json);
      }
      
      // Paramètres par défaut
      return Settings.defaultSettings();
    } catch (e) {
      debugPrint('Erreur lors du chargement des paramètres: $e');
      return Settings.defaultSettings();
    }
  }

  // Sauvegarder les paramètres
  Future<void> saveSettings(Settings settings) async {
    try {
      await StorageHelper.saveJson(AppConstants.keySettings, settings.toJson());
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des paramètres: $e');
    }
  }

  // Mettre à jour le thème
  Future<void> updateTheme(bool isDarkMode) async {
    final settings = await loadSettings();
    settings.isDarkMode = isDarkMode;
    await saveSettings(settings);
  }

  // Mettre à jour le deck actuel
  Future<void> updateCurrentDeck(String deckId) async {
    final settings = await loadSettings();
    settings.currentDeckId = deckId;
    await saveSettings(settings);
  }

}