import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:language_learning_app/core/srs/sm2.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/data/models/game_mode.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';
import 'package:language_learning_app/providers/game_provider.dart';
import 'package:language_learning_app/providers/srs_provider.dart';
import 'package:language_learning_app/screens/games/classic_game/game_screen.dart';

class PreSessionScreen extends StatelessWidget {
  final Deck deck;
  final GameType mode;
  final String title;

  const PreSessionScreen({
    super.key,
    required this.deck,
    required this.mode,
    required this.title,
  });

  List<String> _srsKeys() => mode == GameType.sentence
      ? deck.sentences.map((s) => '${deck.id}::${s.id}').toList()
      : deck.words.map((w) => w.id).toList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final srs = context.watch<SrsProvider>();
    final now = DateTime.now();
    final keys = _srsKeys();
    final c = srs.counts(keys, now);

    final rows = <(SessionFilter, String, String, int)>[
      (SessionFilter.due, l10n.srsFilterDue, l10n.srsFilterDueDesc, c.due),
      (SessionFilter.fresh, l10n.srsFilterFresh, l10n.srsFilterFreshDesc, c.fresh),
      (SessionFilter.hard, l10n.srsFilterHard, l10n.srsFilterHardDesc, c.hard),
      (SessionFilter.all, l10n.srsFilterAll, l10n.srsFilterAllDesc, c.all),
    ];

    final last = srs.filterFor(deck.id, mode);
    final preselect = rows.any((r) => r.$1 == last && r.$4 > 0)
        ? last
        : rows.firstWhere((r) => r.$4 > 0, orElse: () => rows.last).$1;

    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l10n.preSessionTitle,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            for (final (filter, label, desc, count) in rows)
              _FilterCard(
                label: label,
                desc: desc,
                count: count,
                countLabel: l10n.srsCount(count),
                selected: filter == preselect,
                enabled: count > 0 || filter == SessionFilter.all,
                onTap: () => _start(context, filter),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _start(BuildContext context, SessionFilter filter) async {
    final srs = context.read<SrsProvider>();
    final game = context.read<GameProvider>();
    await srs.setFilterFor(deck.id, mode, filter);
    await game.setDeck(deck, gameMode: mode, filter: filter);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GameScreen(gameTitle: title)),
    );
  }
}

class _FilterCard extends StatelessWidget {
  final String label, desc, countLabel;
  final int count;
  final bool selected, enabled;
  final VoidCallback onTap;
  const _FilterCard({
    required this.label,
    required this.desc,
    required this.count,
    required this.countLabel,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Card(
        elevation: 0,
        color: selected
            ? AppColors.primary.withValues(alpha: 0.1)
            : Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text(desc),
          trailing: Text(countLabel,
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold)),
          onTap: enabled ? onTap : null,
        ),
      ),
    );
  }
}
