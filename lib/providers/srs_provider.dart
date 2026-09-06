import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:language_learning_app/core/srs/sm2.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';
import 'package:language_learning_app/data/models/game_mode.dart';

/// The SM-2 schedule. One [SrsCard] per srsKey (word id, or
/// `<deckId>::<sentenceId>` for sentences). Own SharedPreferences keys,
/// GoalProvider pattern — not the codegen Settings model.
class SrsProvider extends ChangeNotifier {
  static const _kState = 'srs_state';
  static const _kFilters = 'session_filter_by_deck';

  final Map<String, SrsCard> _cards = {};
  final Map<String, SessionFilter> _filters = {};

  void load() {
    final raw = StorageHelper.getString(_kState);
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        map.forEach((k, v) {
          _cards[k] = SrsCard.fromJson(v as Map<String, dynamic>);
        });
      } catch (e) {
        debugPrint('SrsProvider: corrupt srs_state, ignoring: $e');
      }
    }
    final rawF = StorageHelper.getString(_kFilters);
    if (rawF != null) {
      try {
        final map = jsonDecode(rawF) as Map<String, dynamic>;
        map.forEach((k, v) {
          _filters[k] = SessionFilter.values.firstWhere(
            (f) => f.name == v,
            orElse: () => SessionFilter.due,
          );
        });
      } catch (_) {}
    }
    notifyListeners();
  }

  SrsCard? cardFor(String srsKey) => _cards[srsKey];

  bool isNew(String srsKey) => _cards[srsKey] == null;

  bool isDue(String srsKey, DateTime now) {
    final c = _cards[srsKey];
    return c == null || !c.due.isAfter(dateOnly(now));
  }

  bool isDifficult(String srsKey) {
    final c = _cards[srsKey];
    return c != null && c.lastQuality < 4;
  }

  bool matches(SessionFilter f, String srsKey, DateTime now) => switch (f) {
        SessionFilter.all => true,
        SessionFilter.due => isDue(srsKey, now),
        SessionFilter.fresh => isNew(srsKey),
        SessionFilter.hard => isDifficult(srsKey),
      };

  ({int all, int due, int fresh, int hard}) counts(
      Iterable<String> srsKeys, DateTime now) {
    var all = 0, due = 0, fresh = 0, hard = 0;
    for (final k in srsKeys) {
      all++;
      if (isDue(k, now)) due++;
      if (isNew(k)) fresh++;
      if (isDifficult(k)) hard++;
    }
    return (all: all, due: due, fresh: fresh, hard: hard);
  }

  int dueOn(Iterable<String> srsKeys, DateTime day) {
    final d = dateOnly(day);
    var n = 0;
    for (final k in srsKeys) {
      if (_cards[k]?.due == d) n++;
    }
    return n;
  }

  Future<void> grade(String srsKey, int quality) async {
    final current = _cards[srsKey] ?? SrsCard.initial(DateTime.now());
    _cards[srsKey] = reviewCard(current, quality, DateTime.now());
    await _persistState();
    notifyListeners();
  }

  Future<void> resetKeys(Iterable<String> srsKeys) async {
    var changed = false;
    for (final k in srsKeys) {
      if (_cards.remove(k) != null) changed = true;
    }
    if (changed) {
      await _persistState();
      notifyListeners();
    }
  }

  SessionFilter filterFor(String deckId, GameType mode) =>
      _filters['${deckId}_${mode.storageId}'] ?? SessionFilter.due;

  Future<void> setFilterFor(
      String deckId, GameType mode, SessionFilter f) async {
    _filters['${deckId}_${mode.storageId}'] = f;
    await StorageHelper.saveString(
      _kFilters,
      jsonEncode(_filters.map((k, v) => MapEntry(k, v.name))),
    );
    notifyListeners();
  }

  Future<void> _persistState() async {
    await StorageHelper.saveString(
      _kState,
      jsonEncode(_cards.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }
}
