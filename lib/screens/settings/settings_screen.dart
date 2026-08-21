import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:language_learning_app/providers/theme_provider.dart';
import 'package:language_learning_app/providers/deck_provider.dart';
import 'package:language_learning_app/providers/game_provider.dart';
import 'package:language_learning_app/providers/locale_provider.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/screens/decks/decks_screen.dart';
import 'package:language_learning_app/screens/stats/statistics_screen.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';
import 'package:language_learning_app/core/extensions/deck_extensions.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_tile.dart';
import 'widgets/clear_data_dialog.dart';
import 'widgets/reset_deck_dialog.dart';
import 'widgets/language_bottom_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                // --- APPARENCE ---
                SettingsSection(
                  title: l10n.appearance,
                  icon: Icons.palette_outlined,
                  children: [
                    _buildThemeSwitch(context, l10n),
                    _buildLanguageTile(context, l10n),
                  ],
                ),

                const SizedBox(height: 24),

                // --- DECK ACTUEL ---
                SettingsSection(
                  title: l10n.currentDeck,
                  icon: Icons.library_books_outlined,
                  children: [
                    _buildCurrentDeckTile(context, l10n),
                  ],
                ),

                const SizedBox(height: 24),

                // --- STATISTIQUES ---
                SettingsSection(
                  title: l10n.statistics,
                  icon: Icons.bar_chart,
                  children: [
                    SettingsTile(
                      title: l10n.viewStatistics,
                      subtitle: l10n.trackYourProgress,
                      icon: Icons.trending_up,
                      iconColor: Colors.blue,
                      showDivider: false,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StatisticsScreen()),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // --- DONNÉES ---
                SettingsSection(
                  title: l10n.data,
                  icon: Icons.storage_outlined,
                  children: [
                    SettingsTile(
                      title: l10n.resetCurrentDeck,
                      subtitle: l10n.restartFromBeginning,
                      icon: Icons.refresh,
                      iconColor: AppColors.warning,
                      onTap: () => ResetDeckDialog.show(context),
                    ),
                    SettingsTile(
                      title: l10n.clearAllData,
                      subtitle: l10n.deleteAllProgress,
                      icon: Icons.delete_forever,
                      iconColor: AppColors.error,
                      showDivider: false,
                      onTap: () => ClearDataDialog.show(context),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // --- À PROPOS ---
                _buildAboutSection(context, l10n),
                
                const SizedBox(height: 40),
                
                // Version en bas de page
                Center(
                  child: Text(
                    'v1.0.0',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WIDGETS DE CONTENU
  // ---------------------------------------------------------------------------

  Widget _buildThemeSwitch(BuildContext context, AppLocalizations l10n) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return SwitchListTile.adaptive(
          title: Text(
            l10n.darkMode,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: Text(
            themeProvider.isDarkMode ? l10n.darkModeEnabled : l10n.lightModeEnabled,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          value: themeProvider.isDarkMode,
          activeTrackColor: AppColors.primary, 
          onChanged: (_) => themeProvider.toggleTheme(),
        );
      },
    );
  }

  Widget _buildLanguageTile(BuildContext context, AppLocalizations l10n) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        final currentLang = {
          'fr': 'Français',
          'en': 'English',
          'es': 'Español',
          'it': 'Italiano',
        }[localeProvider.locale.languageCode] ?? 'English';

        return SettingsTile(
          title: l10n.language,
          subtitle: currentLang,
          icon: Icons.language,
          iconColor: Colors.blueGrey,
          showDivider: false,
          onTap: () => LanguageBottomSheet.show(context, localeProvider),
        );
      },
    );
  }

  Widget _buildCurrentDeckTile(BuildContext context, AppLocalizations l10n) {
    return Consumer2<DeckProvider, GameProvider>(
      builder: (context, deckProvider, gameProvider, _) {
        final deck = deckProvider.selectedDeck;

        if (deck == null) {
          return ListTile(
            title: Text(l10n.noDeck),
            subtitle: Text(l10n.chooseDeckToStart),
            leading: const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          );
        }

        final progress = gameProvider.progress / 100;
        final isCompleted = gameProvider.isCompleted;

        return Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  deck.inputType == InputType.text ? Icons.keyboard : Icons.brush,
                  color: AppColors.primary,
                ),
              ),
              title: Text(
                deck.localizedName(context),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${deck.totalWords} ${l10n.words} • ${gameProvider.remainingWords} ${l10n.remaining}',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DecksScreen()),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(72, 0, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted ? AppColors.success : AppColors.primary,
                      ),
                    ),
                  ),
                  if (isCompleted)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                            l10n.completed_plural,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAboutSection(BuildContext context, AppLocalizations l10n) {
    return SettingsSection(
      title: l10n.about,
      icon: Icons.info_outline,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // --- En-tête existant ---
              const CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.school, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.appName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.description,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, height: 1.5),
              ),

              // --- Nouvelle Section : Nouveautés ---
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              
              // Titre de la section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Nouveautés", // Tu peux mettre l10n.whatsNew ici
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Liste des fonctionnalités demandées
              _buildFeatureItem(Icons.bar_chart_rounded, "Nouvelle page de statistique"),
              _buildFeatureItem(Icons.language, "Nouvelle langue : Italien"),
              _buildFeatureItem(Icons.swap_horizontal_circle_outlined, "Nouveau mode de jeu : Reverse"),
              _buildFeatureItem(Icons.style, "Nouvel ensemble de deck : A2 key"),
              _buildFeatureItem(Icons.auto_fix_high, "Optimisation et amélioration du visuel"),

              // --- Footer existant ---
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.madeWithLove,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  const SizedBox(width: 4),
                  const Icon(Icons.favorite, color: Colors.red, size: 14),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Méthode helper pour afficher une ligne de fonctionnalité
  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}