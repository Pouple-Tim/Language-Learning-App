import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:country_flags/country_flags.dart';
import '../../providers/theme_provider.dart';
import '../../providers/deck_provider.dart';
import '../../providers/game_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/storage_helper.dart';
import '../../data/models/deck.dart';
import '../decks/decks_screen.dart';
import '../../providers/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/extensions/deck_extensions.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_tile.dart';


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
                      onTap: () => _showResetDeckDialog(context),
                    ),
                    SettingsTile(
                      title: l10n.clearAllData,
                      subtitle: l10n.deleteAllProgress,
                      icon: Icons.delete_forever,
                      iconColor: AppColors.error,
                      showDivider: false, // Pas de ligne en bas du dernier élément
                      onTap: () => _showClearDataDialog(context),
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
  // WIDGETS DE CONTENU SPÉCIFIQUES
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

  // ... (Rest of the file is unchanged, but included for completeness)
  Widget _buildLanguageTile(BuildContext context, AppLocalizations l10n) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        final currentLang = {
          'fr': 'Français',
          'en': 'English',
          'es': 'Español',
        }[localeProvider.locale.languageCode] ?? 'English';

        return SettingsTile(
          title: l10n.language,
          subtitle: currentLang,
          icon: Icons.language,
          iconColor: Colors.blueGrey,
          showDivider: false,
          onTap: () => _showLanguageBottomSheet(context, localeProvider),
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
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.madeWithLove, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
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

  void _showLanguageBottomSheet(BuildContext context, LocaleProvider localeProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            _buildLanguageItem(context, localeProvider, 'fr', 'Français', 'FR'),
            _buildLanguageItem(context, localeProvider, 'en', 'English', 'GB'),
            _buildLanguageItem(context, localeProvider, 'es', 'Español', 'ES'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageItem(BuildContext context, LocaleProvider provider, String code, String name, String countryCode) {
    final isSelected = provider.locale.languageCode == code;
    return ListTile(
      leading: SizedBox(
        width: 32,
        height: 24,
        child: CountryFlag.fromCountryCode(
          countryCode,
          theme: const ImageTheme(
                    shape: RoundedRectangle(4),
                  ),
        ),
      ),
      title: Text(
        name,
        style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
      ),
      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
      onTap: () {
        provider.setLocale(Locale(code));
        Navigator.pop(context);
      },
    );
  }

  void _showResetDeckDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gameProvider = context.read<GameProvider>();
    final deckProvider = context.read<DeckProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetDeck),
        content: Text(l10n.resetDeckMessage),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () async {
              await gameProvider.resetDeck();
              await deckProvider.refreshSelectedDeck();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.deckReset), backgroundColor: AppColors.success),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            child: Text(l10n.reset),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.warning, style: const TextStyle(color: AppColors.error)),
        content: Text(l10n.clearDataWarning),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () async {
              await StorageHelper.clear();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.allDataCleared), backgroundColor: AppColors.error),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.clearAll),
          ),
        ],
      ),
    );
  }
}