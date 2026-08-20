# Phase 1 Refactor — Spec

**Source:** Grilling/interview session with the project owner, 2026-08-20. This captures the decisions reached before any implementation started. Supabase migration (Phase 2) was interviewed in the same session but is a separate, later initiative — it is deliberately out of scope here.

## Context

The user asked to review the whole codebase's structure and business logic ("the code works overall but I find it poorly done"). A read-only exploration of the codebase (architecture, providers, models, game modes, tests, and the in-flight sentence-builder diff) was run first, so the interview only asked questions the code couldn't answer itself. The sentence-builder game mode was mid-flight (uncommitted, +718/-136) at the start of the interview and has since been finished and pushed (commit `b900bca "prechangement avant refacto"` on `develop`) — it is stable baseline for this plan, not something to redo.

## Decisions (numbered as asked during the interview)

- **Q1 — sequencing of the in-flight sentence-builder work:** it was finished and pushed before this plan was written. Baseline is clean.
- **Q2 — backward compatibility of locally saved progress:** none required. `SharedPreferences` keys/schemas (progress, custom decks, stats) may change freely; nothing needs a migration path.
- **Q3 — depth of this pass:** broad, root-cause restructuring where duplication/inconsistency was found — not a surface patch of the four symptom sites alone.
- **Q4 — testing:** add the tests necessary for technical soundness and robustness. Clarified in Q16: since there is no auth/network surface in Phase 1, "robustness" means deck-JSON parsing failing gracefully on malformed input, not auth/RLS testing (that's Phase 2's concern).
- **Q5 — Supabase scope:** a separate initiative (Phase 2), not part of this plan. This plan's only obligation toward it is to leave `DeckRepository` with a clean interface (no `SharedPreferences`/file-system leakage into providers) so Phase 2 can be additive.
- **Q6 — mode-identity restructuring:** replace the fragmented mode-identity system (duplicated across `GameProvider`, `game_screen.dart`, `statistics_provider.dart`, `game_mode_stats_widget.dart`, and a stale hardcoded list in `deck_repository.dart`) with a single source of truth, not a minimal patch to the `GameType` enum alone.
- **Q7 — `Word` schema cleanup:** the dead `meaning` JSON field is removed from the deck data (not added to the model). `Word` gains a stable `id` (mirroring `Sentence`), replacing today's fragile progress-restore matching by `prompt`/`answer` content.
- **Q14 — `Sentence` serialization:** converted to the same `json_serializable` codegen pattern used by `Word`/`Deck`, replacing its current hand-written `fromJson`/`toJson`.
- **Q15 — UI decomposition:** `game_screen.dart` (454 lines, ~10 private `_build*` methods) is broken into sub-widgets; `home_screen.dart`'s inline `GameMode` list construction is hoisted out of `build()`.
- **Q16 — security-test scope for Phase 1:** robustness of deck-JSON parsing against malformed input. Auth/RLS/network testing is explicitly Phase 2.

## Concrete pain points this plan addresses (from the exploration report)

1. `GameType` (`lib/data/models/game_mode.dart`) has no `reverse` value — "reverse" is faked via the `id` string while `type` stays `GameType.classic`. This is the root cause of the mode-identity duplication.
2. Mode id→label→behavior mapping is duplicated across `game_provider.dart`, `game_screen.dart` (3 spots), `statistics_provider.dart`, and `game_mode_stats_widget.dart` (which re-derives the mode by substring-matching the *display label*, not the id — one layer removed from already-fragile).
3. `deck_repository.dart:152` (`resetAllProgressForDeck`) hardcodes `['classic', 'reverse']`, silently missing `quiz`/`sentence` — stale since those modes were added.
4. `routeName` on `GameMode` is set on every instance but never read anywhere (`app.dart` has no route table).
5. `word.dart`/`word.g.dart` don't declare `meaning`, yet it's present in ~19 of 44 deck JSON files and silently dropped on every `toJson()` round-trip.
6. `Word` identity is structural (`prompt`/`answer` equality); progress restore in `game_provider.dart` (~lines 139, 150) matches saved words to fresh ones by `prompt` inside an empty `catch (_) {}` — silently fails if a word's text changes between deck revisions.
7. `Sentence` hand-writes its JSON (de)serialization while every sibling model uses `json_serializable` codegen.
8. `game_provider.dart` (421 lines) had zero tests before this plan — the riskiest file in the codebase (answer checking, quiz distractors, sentence validation, progress restore/merge).
9. `game_screen.dart` mixes layout, a bottom-sheet builder, and word-list rendering in one 454-line `StatelessWidget`.
10. `home_screen.dart` rebuilds its `GameMode` config list inline on every `build()`.

## Explicitly out of scope for this plan

- Anything Supabase-related (schema, client, provisioning, `DeckRepository` remote-source implementation).
- Auth, RLS, or network-security testing.
- `review_history.dart` / `ReviewEntry` schema changes (its `gameMode` field stays `String?`; `GameType.storageId` is used to populate it).
- Migrating/preserving any existing locally saved progress or stats.
- Adding widget/integration tests for screens (only `game_provider.dart`, `statistics_provider.dart`, `deck_repository.dart`, and the model layer get new automated tests, per Q4/Q16's scope).
