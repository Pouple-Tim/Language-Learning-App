import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Assurez-vous que le chemin d'importation correspond à votre structure de projet
import 'package:language_learning_app/core/utils/storage_helper.dart';

void main() {
  group('StorageHelper Tests', () {
    
    // Cette fonction s'exécute avant chaque test
    setUp(() async {
      // Mock initial vide pour SharedPreferences
      SharedPreferences.setMockInitialValues({});
      // Initialise le helper
      await StorageHelper.init();
    });

    test('Sauvegarde et récupère une String', () async {
      const key = 'test_string';
      const value = 'Hello World';

      final success = await StorageHelper.saveString(key, value);
      expect(success, isTrue);

      final retrieved = StorageHelper.getString(key);
      expect(retrieved, value);
    });

    test('Sauvegarde et récupère un Bool', () async {
      const key = 'test_bool';
      
      await StorageHelper.saveBool(key, true);
      expect(StorageHelper.getBool(key), isTrue);

      await StorageHelper.saveBool(key, false);
      expect(StorageHelper.getBool(key), isFalse);
    });

    test('Retourne null pour une clé inexistante', () {
      expect(StorageHelper.getString('non_existent_key'), isNull);
      expect(StorageHelper.getBool('non_existent_key'), isNull);
      expect(StorageHelper.getJson('non_existent_key'), isNull);
    });

    test('Sauvegarde et récupère un JSON (Map)', () async {
      const key = 'test_json';
      final data = {'id': 1, 'name': 'Test User', 'isActive': true};

      final success = await StorageHelper.saveJson(key, data);
      expect(success, isTrue);

      final retrieved = StorageHelper.getJson(key);
      expect(retrieved, isNotNull);
      expect(retrieved!['id'], 1);
      expect(retrieved['name'], 'Test User');
    });

    test('Sauvegarde et récupère une liste JSON', () async {
      const key = 'test_json_list';
      final list = [
        {'id': 1, 'val': 'A'},
        {'id': 2, 'val': 'B'}
      ];

      final success = await StorageHelper.saveJsonList(key, list);
      expect(success, isTrue);

      final retrieved = StorageHelper.getJsonList(key);
      expect(retrieved, isNotNull);
      expect(retrieved!.length, 2);
      expect(retrieved[0]['val'], 'A');
    });

    test('Gère correctement les données corrompues (getJson)', () async {
      // On injecte manuellement une string qui n'est pas du JSON valide
      SharedPreferences.setMockInitialValues({
        'corrupted_key': '{ceci n\'est pas du json}'
      });
      // On doit réinitialiser pour prendre en compte le mock
      await StorageHelper.init();

      final result = StorageHelper.getJson('corrupted_key');
      expect(result, isNull); // Le bloc try-catch doit retourner null
    });

    test('remove supprime une clé spécifique', () async {
      await StorageHelper.saveString('keep', 'me');
      await StorageHelper.saveString('delete', 'me');

      await StorageHelper.remove('delete');

      expect(StorageHelper.getString('delete'), isNull);
      expect(StorageHelper.getString('keep'), 'me');
    });

    test('clear supprime tout', () async {
      await StorageHelper.saveString('key1', 'val1');
      await StorageHelper.saveBool('key2', true);

      await StorageHelper.clear();

      expect(StorageHelper.getString('key1'), isNull);
      expect(StorageHelper.getBool('key2'), isNull);
    });
  });
}