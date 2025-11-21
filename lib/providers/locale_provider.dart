import 'package:flutter/material.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('fr'); // Français par défaut

  Locale get locale => _locale;

  // Charger la locale sauvegardée
  Future<void> loadLocale() async {
    final languageCode = StorageHelper.getString('language_code');
    if (languageCode != null) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  // Changer la locale
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await StorageHelper.saveString('language_code', locale.languageCode);
    notifyListeners();
  }
}