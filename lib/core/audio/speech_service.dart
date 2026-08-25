import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' show SpeechToText, SpeechListenOptions;

/// Push-to-talk speech recognition for the pronunciation game, using the
/// device's native zh-CN speech engine. One shared SpeechToText instance,
/// availability (and the OS permission prompt) checked lazily on first use.
class SpeechService {
  static final SpeechToText _speech = SpeechToText();
  static void Function()? _onDone;

  static Future<bool> _ensureInitialized() async {
    try {
      // SpeechToText.initialize() already memoizes a successful init
      // internally, so there's no need for our own "already checked" flag --
      // and caching a *negative* result would trap a user who denies the mic
      // permission, then grants it from system settings without restarting
      // the app.
      return await _speech.initialize(
        onStatus: (status) {
          if (status == SpeechToText.doneStatus || status == SpeechToText.notListeningStatus) {
            _onDone?.call();
          }
        },
      );
    } catch (e) {
      debugPrint('⚠️ SpeechService.initialize failed: $e');
      return false;
    }
  }

  /// Starts a listening session. [onFinalResult] is called once, with the
  /// recognized text, when the session ends (either the recognizer detects
  /// end of speech on its own, or [stopListening] is called) -- never with
  /// interim/partial results.
  ///
  /// [onDone] is called when the recognition session ends for any reason
  /// (status `done`/`notListening`) -- including when it ends *without* ever
  /// producing a final result (e.g. silence, or no speech model installed).
  ///
  /// Returns `false` (without calling [onFinalResult]) if the microphone or
  /// speech recognizer isn't available -- the caller should surface an error
  /// in that case.
  static Future<bool> startListening(
    void Function(String recognizedWords) onFinalResult, {
    void Function()? onDone,
  }) async {
    final available = await _ensureInitialized();
    if (!available) return false;

    _onDone = onDone;
    try {
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            onFinalResult(result.recognizedWords);
          }
        },
        listenOptions: SpeechListenOptions(localeId: 'zh-CN'),
      );
    } catch (e) {
      debugPrint('⚠️ SpeechService.listen failed: $e');
      return false;
    }
    return true;
  }

  static Future<void> stopListening() => _speech.stop();
}
