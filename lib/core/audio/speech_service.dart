import 'package:speech_to_text/speech_to_text.dart' show SpeechToText, SpeechListenOptions;

/// Push-to-talk speech recognition for the pronunciation game, using the
/// device's native zh-CN speech engine. One shared SpeechToText instance,
/// availability (and the OS permission prompt) checked lazily on first use.
class SpeechService {
  static final SpeechToText _speech = SpeechToText();
  static bool _available = false;
  static bool _checkedAvailability = false;

  static Future<bool> _ensureInitialized() async {
    if (!_checkedAvailability) {
      _available = await _speech.initialize();
      _checkedAvailability = true;
    }
    return _available;
  }

  /// Starts a listening session. [onFinalResult] is called once, with the
  /// recognized text, when the session ends (either the recognizer detects
  /// end of speech on its own, or [stopListening] is called) -- never with
  /// interim/partial results.
  ///
  /// Returns `false` (without calling [onFinalResult]) if the microphone or
  /// speech recognizer isn't available -- the caller should surface an error
  /// in that case.
  static Future<bool> startListening(void Function(String recognizedWords) onFinalResult) async {
    final available = await _ensureInitialized();
    if (!available) return false;

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          onFinalResult(result.recognizedWords);
        }
      },
      listenOptions: SpeechListenOptions(localeId: 'zh-CN'),
    );
    return true;
  }

  static Future<void> stopListening() => _speech.stop();
}
