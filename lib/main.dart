import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/utils/storage_helper.dart';
import 'providers/theme_provider.dart';
import 'providers/game_provider.dart';
import 'providers/deck_provider.dart';
import 'providers/locale_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await StorageHelper.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => DeckProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}