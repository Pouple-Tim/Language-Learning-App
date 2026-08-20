import 'package:flutter_test/flutter_test.dart';
import 'package:language_learning_app/data/models/game_mode.dart';

void main() {
  group('GameType identity', () {
    test('storageId matches the enum name for every value', () {
      for (final type in GameType.values) {
        expect(type.storageId, type.name);
      }
    });

    test('fromStorageId resolves every known storage id back to its GameType', () {
      for (final type in GameType.values) {
        expect(GameTypeIdentity.fromStorageId(type.storageId), type);
      }
    });

    test('fromStorageId falls back to classic for an unknown id', () {
      expect(GameTypeIdentity.fromStorageId('unknown_mode'), GameType.classic);
    });

    test('classic has no badge label, every other mode has one', () {
      expect(GameType.classic.badgeLabel, isEmpty);
      for (final type in GameType.values.where((t) => t != GameType.classic)) {
        expect(type.badgeLabel, isNotEmpty);
      }
    });

    test('every GameType has a non-empty statsLabel', () {
      for (final type in GameType.values) {
        expect(type.statsLabel, isNotEmpty);
      }
    });
  });
}
