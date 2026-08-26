# Écoute & Prononciation — Design

**Source:** Grilling session with the project owner, 2026-08-24 (`mattpocock-skills:grilling`).

## Goal

Add two new practice modes to the existing word-review game system: a **listening** game (hear the word, recognize it) and a **pronunciation** game (say the word, get basic feedback). Both plug into the existing `GameType` enum architecture rather than introducing a parallel system.

## Explicitly out of scope for this pass

- Using the 85 native HSK1 lesson mp3s in `docs/resources/HSK1/HSK 1 Tb audios/` — they're per-lesson (4-10 tracks/lesson), don't map 1:1 to deck words, and no audio-analysis tooling (`ffmpeg`) is installed to segment them. Kept for a possible future "full lesson listening" exercise or, once segmented, as a TTS replacement / pronunciation reference. Not blocking this work.
- True pronunciation/tone scoring (comparing the user's audio to a reference for tone accuracy). V1 pronunciation is "did you say the right word" via basic speech-to-text, not "did you say it correctly."
- Any language/deck other than Chinese HSK1.
- Extending either game to reverse mode, sentence mode, or English decks.

These are deliberately deferred, flagged during grilling, not forgotten.

## Sequencing

Two independent features, each on its own branch off `develop`, built/tested/merged one after another (per [[project-branch-workflow]]):
1. **Listening game** — built first, this plan.
2. **Pronunciation game** — designed here, built in a separate follow-up plan once the listening game is merged.

## Actual deck data shape (corrects an assumption made mid-grilling)

HSK1 words have **no translation field**. `Word.prompt` is pinyin (e.g. `"nǐhǎo"`), `Word.answer` is the hanzi (e.g. `"你好"`) — see `assets/decks/chinese/hsk1/part1-5/chinese_hsk1_part1.json`. The existing `GameType.quiz` mode already tests "pinyin shown as text → pick the correct hanzi among 4 options" (`GameProvider._generateQuizOptions`, `lib/providers/game_provider.dart:344`).

Consequently, the listening game is **not** "hear the word → pick its translation" (no translation exists) but: **hear the hanzi spoken aloud → pick the matching hanzi among 4 options**. Same options-generation logic as quiz, reused as-is. This still matches everything agreed during grilling (audio prompt, QCM answer, manual play button, HSK1 scope) — only the nature of "the answer" is corrected to fit real data.

## Listening game

- **Audio**: `flutter_tts`, locale `zh-CN`, speaking `currentWord.answer` (the hanzi — not `.prompt`, which is romanized pinyin and would be mispronounced or read as Latin letters by a Chinese voice).
- **Mechanic**: reuses `GameType.quiz`'s option-generation (`_generateQuizOptions`) and answer-checking (`checkAnswer`) verbatim — a new `GameType.listening` value triggers the same `spinWheel` branch as quiz.
- **Prompt display**: the word text is never shown before answering (that would defeat a listening exercise) — replaced by a speaker button ("Écouter") the user taps to play/replay the audio, no autoplay.
- **Answer UI**: reuses `QuizWidget` unchanged (it's already generic over `quizOptions`/`checkAnswer`, not quiz-specific).
- **Scope**: HSK1 decks only for this pass, but not deck-restricted in code — works for any deck, same as quiz mode does today.
- **Platforms**: Android + iOS (TTS via native platform engines); dev/testing on Linux desktop is possible for the TTS speaker output (desktop has native TTS too), but the primary manual test pass happens on the project owner's Android phone.

## Pronunciation game (designed now, built later)

- **Approach**: `speech_to_text` package, locale `zh-CN`. Basic recognition only — compares the recognized text to `currentWord.answer` (hanzi) for an exact/near match. No tone scoring (flagged limitation, accepted).
- **Display while recording**: both hanzi and pinyin shown (`currentWord.answer` + `currentWord.prompt`) — unlike listening, no ambiguity is desired here; the point is producing the right sound, not recalling the character.
- **Recording UI**: push-to-talk (hold a mic button to record, release to stop and run recognition) — avoids building silence-detection.
- **Feedback**: incorrect → retry the same word before advancing; correct → advance like other modes.
- **Scope**: HSK1, same as listening.
- **Platforms**: Android + iOS target; `NSMicrophoneUsageDescription`/`NSSpeechRecognitionUsageDescription` need adding to `ios/Runner/Info.plist` (currently absent), and `RECORD_AUDIO` to `android/app/src/main/AndroidManifest.xml` (currently only has `INTERNET`). Manual test pass on Android.
- **Feasibility confirmed**: both `speech_to_text` and `flutter_tts` document `zh-CN`/`zh-TW` locale support on Android/iOS via native platform speech engines.

## Cross-cutting

- New `GameType` enum values plug into the existing exhaustive-switch pattern (`lib/data/models/game_mode.dart`) — `storageId`/`badgeLabel`/`statsLabel` per value, compiler-enforced completeness.
- Each new mode gets a card on the home screen (`lib/screens/home/home_screen.dart`'s `_buildGameModes` list) and l10n keys in all four `.arb` files (`app_en`, `app_fr`, `app_es`, `app_it`), following the `classicModeTitle`/`classicModeDesc` naming pattern.
- No deck JSON/schema changes needed for either game — both work directly off existing `prompt`/`answer` fields.
