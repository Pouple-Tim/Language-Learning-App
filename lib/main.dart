import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/utils/storage_helper.dart';
import 'core/config/supabase_config.dart';
import 'providers/theme_provider.dart';
import 'providers/game_provider.dart';
import 'providers/deck_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/statistics_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await StorageHelper.init();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => DeckProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(
          create: (_) => StatisticsProvider()..loadHistory(),
        ),
        ChangeNotifierProxyProvider<StatisticsProvider, GameProvider>(
          create: (context) => GameProvider(
            statisticsProvider: context.read<StatisticsProvider>(),
          ),
          update: (context, stats, previous) => 
            previous ?? GameProvider(statisticsProvider: stats),
        ),
      ],
      child: const MyApp(),
    ),
  );
}