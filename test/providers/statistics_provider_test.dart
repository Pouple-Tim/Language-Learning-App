import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:language_learning_app/providers/statistics_provider.dart';
import 'package:language_learning_app/data/models/game_mode.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';
import 'package:language_learning_app/data/models/review_history.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageHelper.init();
  });

  group('StatisticsProvider', () {
    test('getGameModeStats groups and sorts by play count, using GameType labels', () async {
      final provider = StatisticsProvider();
      await provider.loadHistory();

      await provider.addReview(wordId: 'w1', deckId: 'd1', wasCorrect: true, inputType: 'text', gameMode: 'classic');
      await provider.addReview(wordId: 'w2', deckId: 'd1', wasCorrect: true, inputType: 'text', gameMode: 'classic');
      await provider.addReview(wordId: 'w3', deckId: 'd1', wasCorrect: false, inputType: 'text', gameMode: 'quiz');

      final stats = provider.getGameModeStats();

      expect(stats.length, 2);
      expect(stats.first.type, GameType.classic);
      expect(stats.first.count, 2);
      expect(stats.first.label, 'Classique');
      expect(stats.last.type, GameType.quiz);
      expect(stats.last.count, 1);
    });

    test('getGameModeStats defaults entries with no gameMode to classic', () async {
      final provider = StatisticsProvider();
      await provider.loadHistory();

      provider.history.addReview(ReviewEntry(
        wordId: 'w1',
        deckId: 'd1',
        reviewedAt: DateTime.now(),
        wasCorrect: true,
        inputType: 'text',
      ));

      final stats = provider.getGameModeStats();
      expect(stats.single.type, GameType.classic);
    });

    test('getSuccessRate computes the percentage of correct reviews', () async {
      final provider = StatisticsProvider();
      await provider.loadHistory();

      await provider.addReview(wordId: 'w1', deckId: 'd1', wasCorrect: true, inputType: 'text', gameMode: 'classic');
      await provider.addReview(wordId: 'w2', deckId: 'd1', wasCorrect: false, inputType: 'text', gameMode: 'classic');
      await provider.addReview(wordId: 'w3', deckId: 'd1', wasCorrect: true, inputType: 'text', gameMode: 'classic');

      expect(provider.getSuccessRate(), closeTo(66.67, 0.01));
    });

    test('getSuccessRate returns 0 for empty history', () async {
      final provider = StatisticsProvider();
      await provider.loadHistory();
      expect(provider.getSuccessRate(), 0.0);
    });

    test('getTotalWordsLearned counts unique correctly-answered wordIds', () async {
      final provider = StatisticsProvider();
      await provider.loadHistory();

      await provider.addReview(wordId: 'w1', deckId: 'd1', wasCorrect: true, inputType: 'text', gameMode: 'classic');
      await provider.addReview(wordId: 'w1', deckId: 'd1', wasCorrect: true, inputType: 'text', gameMode: 'classic');
      await provider.addReview(wordId: 'w2', deckId: 'd1', wasCorrect: false, inputType: 'text', gameMode: 'classic');

      expect(provider.getTotalWordsLearned(), 1);
    });

    test('clearHistory resets to empty', () async {
      final provider = StatisticsProvider();
      await provider.loadHistory();
      await provider.addReview(wordId: 'w1', deckId: 'd1', wasCorrect: true, inputType: 'text', gameMode: 'classic');

      await provider.clearHistory();

      expect(provider.history.entries, isEmpty);
      expect(provider.getSuccessRate(), 0.0);
    });
  });
}
