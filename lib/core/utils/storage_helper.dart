import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageHelper {
  static SharedPreferences? _prefs;

  // Initialiser SharedPreferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Sauvegarder une string
  static Future<bool> saveString(String key, String value) async {
    _prefs ??= await SharedPreferences.getInstance();
    return await _prefs!.setString(key, value);
  }

  // Récupérer une string
  static String? getString(String key) {
    return _prefs?.getString(key);
  }

  // Sauvegarder un objet JSON
  static Future<bool> saveJson(String key, Map<String, dynamic> json) async {
    final jsonString = jsonEncode(json);
    return await saveString(key, jsonString);
  }

  // Récupérer un objet JSON
  static Map<String, dynamic>? getJson(String key) {
    final jsonString = getString(key);
    if (jsonString == null) return null;
    
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // Sauvegarder une liste JSON
  static Future<bool> saveJsonList(String key, List<Map<String, dynamic>> list) async {
    final jsonString = jsonEncode(list);
    return await saveString(key, jsonString);
  }

  // Récupérer une liste JSON
  static List<Map<String, dynamic>>? getJsonList(String key) {
    final jsonString = getString(key);
    if (jsonString == null) return null;
    
    try {
      final decoded = jsonDecode(jsonString);
      return (decoded as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  // Sauvegarder un bool
  static Future<bool> saveBool(String key, bool value) async {
    _prefs ??= await SharedPreferences.getInstance();
    return await _prefs!.setBool(key, value);
  }

  // Récupérer un bool
  static bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  // Supprimer une clé
  static Future<bool> remove(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    return await _prefs!.remove(key);
  }

  // Tout supprimer
  static Future<bool> clear() async {
    _prefs ??= await SharedPreferences.getInstance();
    return await _prefs!.clear();
  }
}