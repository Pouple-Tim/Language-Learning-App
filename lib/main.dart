import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/analytics/analytics_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/utils/storage_helper.dart';
import 'core/config/supabase_config.dart';
import 'core/config/sentry_config.dart';
import 'providers/theme_provider.dart';
import 'providers/game_provider.dart';
import 'providers/deck_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/statistics_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await StorageHelper.init();
  } catch (e) {
    debugPrint('❌ Erreur initialisation StorageHelper: $e');
  }

  await NotificationService.init();

  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
    unawaited(AnalyticsService.logEvent('app_opened'));
  } catch (e) {
    debugPrint('❌ Erreur initialisation Supabase (probablement hors-ligne): $e');
  }

  final sentryConfigured = SentryConfig.dsn.startsWith('http');
  if (!sentryConfigured) {
    debugPrint('⚠️ Sentry désactivé: DSN non configuré (voir sentry_config.dart)');
  }

  await SentryFlutter.init(
    (options) => options.dsn = sentryConfigured ? SentryConfig.dsn : '',
    appRunner: () => runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => DeckProvider()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider(create: (_) => ReminderProvider()..load()),
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
    ),
  );
}