import 'package:flutter_tts/flutter_tts.dart';

/// Speaks Chinese text aloud for the listening game, using the device's
/// native zh-CN voice engine. One shared FlutterTts instance, language
/// configured once on first use.
class TtsService {
  static final FlutterTts _tts = FlutterTts();
  static bool _languageSet = false;

  /// Speaks [text] (expected to be Chinese hanzi, e.g. a Word.answer —
  /// not romanized pinyin, which a zh-CN voice would mispronounce).
  static Future<void> speak(String text) async {
    if (!_languageSet) {
      await _tts.setLanguage('zh-CN');
      _languageSet = true;
    }
    await _tts.stop();
    await _tts.speak(text);
  }
}
