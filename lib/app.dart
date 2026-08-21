import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'providers/theme_provider.dart';
import 'providers/deck_provider.dart';
import 'providers/game_provider.dart';
import 'providers/locale_provider.dart';
import 'data/repositories/settings_repository.dart';
import 'l10n/app_localizations.dart';
import 'screens/home/home_screen.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SettingsRepository _settingsRepository = SettingsRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    // ✅ FIX: Vérifier mounted AVANT d'utiliser context
    if (!mounted) return;
    
    final deckProvider = context.read<DeckProvider>();
    final gameProvider = context.read<GameProvider>();
    final themeProvider = context.read<ThemeProvider>();
    final localeProvider = context.read<LocaleProvider>();

    final settings = await _settingsRepository.loadSettings();

    themeProvider.setDarkMode(settings.isDarkMode);
    await localeProvider.loadLocale();

    await deckProvider.loadDecks();

    if (deckProvider.selectedDeck != null) {
      await gameProvider.setDeck(deckProvider.selectedDeck!);
      await gameProvider.checkDailyReset(settings.lastReset);
      
      // ✅ FIX: Stocker le résultat avant le await
      final needsReset = await _settingsRepository.needsDailyReset();
      
      if (needsReset) {
        await _settingsRepository.updateLastReset(DateTime.now());
        
        // ✅ FIX: Vérifier mounted après tous les awaits
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✨ Nouveau jour ! Deck réinitialisé.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, _) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          
          // Localisation
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('fr'),
            Locale('es'),
            Locale('it'),
          ],
          
          // Thèmes
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          
          home: const HomeScreen(),
        );
      },
    );
  }
}