# Phase 2 — Supabase-Backed Deck Downloads Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stop bundling the 44 base decks' word/sentence content inside the app binary; fetch a deck's content from Supabase the first time a user picks it, then cache it locally for offline reuse.

**Architecture:** The bundled `assets/decks/manifest.json` gains enough per-deck metadata (id, name, input type, word count, whether it has sentences) that `DeckRepository.loadBaseDecks()` can build the full catalog with zero network calls and zero per-file asset reads. A deck's actual `words`/`sentences` are fetched lazily from a single public, read-only Supabase table (`decks`, one JSONB `content` column) the first time `DeckProvider.selectDeck()` is called on it, then cached locally under a per-deck `SharedPreferences` key exactly like the existing `progress_<deckId>_<mode>` keys. `Deck`/`Word`/`Sentence` models are unchanged.

**Tech Stack:** Flutter/Dart, `supabase_flutter` (official SDK, read-only usage in the app), Supabase Postgres + PostgREST (public anon read via RLS), `SharedPreferences` (existing local cache).

**Spec:** `docs/superpowers/specs/2026-08-21-phase2-supabase-decks-design.md`

## Global Constraints

- No auth, no syncing of user data (progress/custom decks/review history/settings) — those stay local-only via `SharedPreferences`, untouched by this plan.
- `Deck`, `Word`, `Sentence` Dart model *shapes* do not change (Approach A: reuse, not replace).
- Keep `flutter analyze` at 0 issues and `flutter test` fully green after every task.
- No widget/integration tests for the new UI states in `DeckCard`/home screen — this repo's convention covers screens via `flutter analyze`/`flutter test` plus manual verification only, not automated widget tests.
- The Supabase project's `service_role` key is a real secret: it is only ever read from an environment variable by the local seed script, never hardcoded, never committed, never shipped in the app. The `anon`/publishable key is safe to commit (protected by RLS) and does live in the app's source.
- Supabase project: URL `https://wkqzhtwzumdgeqdiriwl.supabase.co`, anon/publishable key `sb_publishable_JXiHimDlvvOxCWVFfP0N6g_XUWj-OsM` (both already confirmed with the project owner).

---

### Task 1: Provision the Supabase schema

**Files:**
- Create: `supabase/schema.sql` (checked into the repo for reproducibility/reference — Supabase itself is configured by running this in the dashboard, not by this file being executed automatically)

**Interfaces:**
- Produces: a `decks` table (`id text primary key`, `content jsonb not null`) with RLS allowing public `SELECT` only, that Task 5's seed script writes to and Task 6's `DeckRepository` reads from.

- [ ] **Step 1: Write the schema file**

Create `supabase/schema.sql`:

```sql
create table if not exists public.decks (
  id text primary key,
  content jsonb not null
);

alter table public.decks enable row level security;

create policy "Public read access" on public.decks
  for select
  to anon
  using (true);
```

- [ ] **Step 2: Apply it in the Supabase dashboard**

This step must be done by a human with dashboard access — it cannot be scripted from here without direct Postgres credentials this plan doesn't have.

Open the Supabase dashboard for this project → SQL Editor → paste the contents of `supabase/schema.sql` → Run.

- [ ] **Step 3: Verify the table is publicly readable and empty**

Run:

```bash
curl -s "https://wkqzhtwzumdgeqdiriwl.supabase.co/rest/v1/decks?select=*" \
  -H "apikey: sb_publishable_JXiHimDlvvOxCWVFfP0N6g_XUWj-OsM" \
  -H "Authorization: Bearer sb_publishable_JXiHimDlvvOxCWVFfP0N6g_XUWj-OsM"
```

Expected: `[]` (HTTP 200, empty JSON array). Any other response (404, 401, a Postgres error) means the table or policy wasn't created correctly — re-check Step 2 before continuing.

- [ ] **Step 4: Commit**

```bash
git add supabase/schema.sql
git commit -m "chore: add Supabase decks table schema"
```

---

### Task 2: Add `supabase_flutter` and initialize the client

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/core/config/supabase_config.dart`
- Modify: `lib/main.dart`

**Interfaces:**
- Produces: `SupabaseConfig.url`, `SupabaseConfig.anonKey` (consumed by Task 6's `DeckRepository`); `Supabase.instance.client` is initialized and ready before any provider runs.

- [ ] **Step 1: Add the dependency**

In `pubspec.yaml`, under `dependencies:`, add (alphabetically near the other single-purpose packages, matching the file's existing style of one-line comments per group):

```yaml
  # Backend (contenu des decks de base)
  supabase_flutter: ^2.17.2
```

Run: `flutter pub get`

- [ ] **Step 2: Add the config constants**

Create `lib/core/config/supabase_config.dart`:

```dart
/// Project URL and anon/publishable key for the Supabase backend that
/// serves base-deck content. The anon key is safe to embed client-side --
/// it is not a secret, and all writes are blocked by Row Level Security
/// (see supabase/schema.sql). Never put the service_role key here.
class SupabaseConfig {
  static const String url = 'https://wkqzhtwzumdgeqdiriwl.supabase.co';
  static const String anonKey = 'sb_publishable_JXiHimDlvvOxCWVFfP0N6g_XUWj-OsM';
}
```

- [ ] **Step 3: Initialize it in `main.dart`**

Modify `lib/main.dart`:

```dart
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
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(
```

(The rest of the file — the `MultiProvider(...)` block — is unchanged.)

- [ ] **Step 4: Verify**

Run: `flutter analyze` — expect: No issues found!
Run: `flutter test` — expect: all existing tests still pass (this task adds no new tests; it's pure wiring, verified by the app still analyzing/compiling cleanly).

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/core/config/supabase_config.dart lib/main.dart
git commit -m "feat: add supabase_flutter and initialize the client"
```

---

### Task 3: Enrich the deck manifest model with content-summary fields

**Files:**
- Modify: `lib/data/models/deck_manifest.dart`
- Modify: `test/data/models/deck_manifest_test.dart`

**Interfaces:**
- Consumes: `InputType` enum from `lib/data/models/deck.dart`.
- Produces: `DeckEntry` gains `id: String`, `name: String`, `inputType: InputType`, `reverseInputType: InputType?`, `wordCount: int`, `hasSentences: bool` — consumed by Task 4 (generator), Task 7 (`DeckRepository.loadBaseDecks`), Task 9 (`DeckCard`), and Task 10 (home screen).

- [ ] **Step 1: Write the failing test**

Replace `test/data/models/deck_manifest_test.dart` in full:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:language_learning_app/data/models/deck_manifest.dart';
import 'package:language_learning_app/data/models/deck.dart';

void main() {
  group('DeckEntry Model Tests', () {
    test('Category logic works correctly', () {
      final entry1 = DeckEntry(
        path: 'p1',
        categories: ['Hiragana'],
        id: 'd1',
        name: 'D1',
        inputType: InputType.text,
        wordCount: 5,
        hasSentences: false,
      );
      expect(entry1.category, 'Hiragana');
      expect(entry1.subcategory, 'Hiragana');

      final entry2 = DeckEntry(
        path: 'p2',
        categories: ['Japonais', 'Grammaire', 'N5'],
        id: 'd2',
        name: 'D2',
        inputType: InputType.text,
        wordCount: 5,
        hasSentences: false,
      );
      expect(entry2.category, 'Japonais');
      expect(entry2.subcategory, 'Grammaire > N5');

      final entry3 = DeckEntry(
        path: 'p3',
        categories: [],
        id: 'd3',
        name: 'D3',
        inputType: InputType.text,
        wordCount: 5,
        hasSentences: false,
      );
      expect(entry3.category, 'Autres');
      expect(entry3.subcategory, 'Autres');
    });

    test('Default values work in Constructor and JSON', () {
      final entry = DeckEntry(
        path: 'path',
        categories: ['Test'],
        id: 'd1',
        name: 'D1',
        inputType: InputType.text,
        wordCount: 5,
        hasSentences: false,
      );
      expect(entry.difficulty, 'beginner');

      final jsonMap = {
        'path': 'path',
        'categories': ['Test'],
        'id': 'd1',
        'name': 'D1',
        'inputType': 'text',
        'wordCount': 5,
        'hasSentences': false,
        // 'difficulty' is missing
      };
      final fromJson = DeckEntry.fromJson(jsonMap);
      expect(fromJson.difficulty, 'beginner');
    });

    test('Full JSON Serialization', () {
      final entry = DeckEntry(
        path: 'assets/deck.json',
        categories: ['A', 'B'],
        difficulty: 'hard',
        id: 'd1',
        name: 'D1',
        inputType: InputType.draw,
        reverseInputType: InputType.text,
        wordCount: 12,
        hasSentences: true,
      );

      final json = entry.toJson();
      expect(json['difficulty'], 'hard');
      expect(json['categories'], ['A', 'B']);
      expect(json['wordCount'], 12);
      expect(json['hasSentences'], true);

      final reconstructed = DeckEntry.fromJson(json);
      expect(reconstructed.path, entry.path);
      expect(reconstructed.wordCount, 12);
      expect(reconstructed.hasSentences, isTrue);
    });
  });

  group('DeckManifest Model Tests', () {
    test('Parses nested DeckEntry list correctly', () {
      final json = {
        'version': '1.0',
        'lastUpdate': '2023-01-01',
        'decks': [
          {
            'path': 'd1',
            'categories': ['C1'],
            'id': 'd1',
            'name': 'D1',
            'inputType': 'text',
            'wordCount': 3,
            'hasSentences': false,
          },
          {
            'path': 'd2',
            'categories': ['C2'],
            'difficulty': 'expert',
            'id': 'd2',
            'name': 'D2',
            'inputType': 'draw',
            'wordCount': 8,
            'hasSentences': true,
          },
        ],
      };

      final manifest = DeckManifest.fromJson(json);

      expect(manifest.version, '1.0');
      expect(manifest.decks.length, 2);
      expect(manifest.decks[0].category, 'C1');
      expect(manifest.decks[1].difficulty, 'expert');
      expect(manifest.decks[1].wordCount, 8);
      expect(manifest.decks[1].hasSentences, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/data/models/deck_manifest_test.dart`
Expected: FAIL — compile errors, `DeckEntry`'s constructor doesn't recognize `id`/`name`/`inputType`/`wordCount`/`hasSentences`.

- [ ] **Step 3: Implement**

Replace `lib/data/models/deck_manifest.dart` in full:

```dart
import 'package:json_annotation/json_annotation.dart';
import 'deck.dart';

part 'deck_manifest.g.dart';

@JsonSerializable()
class DeckManifest {
  final String version;
  final String lastUpdate;
  final List<DeckEntry> decks;

  DeckManifest({
    required this.version,
    required this.lastUpdate,
    required this.decks,
  });

  factory DeckManifest.fromJson(Map<String, dynamic> json) =>
      _$DeckManifestFromJson(json);
  Map<String, dynamic> toJson() => _$DeckManifestToJson(this);
}

@JsonSerializable()
class DeckEntry {
  final String path;
  final List<String> categories; // 👈 Hiérarchie de catégories

  @JsonKey(defaultValue: 'beginner')
  final String difficulty;

  final String id;
  final String name;

  @JsonKey(unknownEnumValue: InputType.text)
  final InputType inputType;

  @JsonKey(unknownEnumValue: InputType.text)
  final InputType? reverseInputType;

  final int wordCount;
  final bool hasSentences;

  DeckEntry({
    required this.path,
    required this.categories,
    this.difficulty = 'beginner',
    required this.id,
    required this.name,
    required this.inputType,
    this.reverseInputType,
    required this.wordCount,
    required this.hasSentences,
  });

  // Helpers pour compatibilité
  String get category => categories.isNotEmpty ? categories.first : 'Autres';
  String get subcategory => categories.length > 1 ? categories.sublist(1).join(' > ') : category;

  factory DeckEntry.fromJson(Map<String, dynamic> json) =>
      _$DeckEntryFromJson(json);
  Map<String, dynamic> toJson() => _$DeckEntryToJson(this);
}
```

Run: `dart run build_runner build --delete-conflicting-outputs` (regenerates `deck_manifest.g.dart`).

- [ ] **Step 4: Run it to verify it passes**

Run: `flutter test test/data/models/deck_manifest_test.dart`
Expected: PASS, all tests green.

- [ ] **Step 5: Full suite + analyze**

Run: `flutter analyze` — expect: No issues found! (other call sites constructing `DeckEntry` don't exist yet outside the generator script, which Task 4 updates next).
Run: `flutter test` — expect: all pass.

- [ ] **Step 6: Commit**

```bash
git add lib/data/models/deck_manifest.dart lib/data/models/deck_manifest.g.dart test/data/models/deck_manifest_test.dart
git commit -m "feat: add content-summary fields to DeckEntry"
```

---

### Task 4: Update the manifest generator to emit the new fields

**Files:**
- Modify: `tool/generate_deck_manifest.dart`

**Interfaces:**
- Consumes: nothing from earlier tasks (standalone script), but its *output* (`assets/decks/manifest.json`) must match the shape Task 3 defined.
- Produces: a regenerated `assets/decks/manifest.json` with `id`/`name`/`inputType`/`reverseInputType`/`wordCount`/`hasSentences` per entry, consumed by Task 7.

- [ ] **Step 1: Modify the generator**

In `tool/generate_deck_manifest.dart`, replace the block that builds each entry:

```dart
        deckFiles.add({
          'path': path,
          'categories': categories,
          'difficulty': difficulty,
        });

        stdout.writeln('  ✅ $name → ${categories.join(' > ')}');
```

with:

```dart
        final words = json['words'] as List?;
        final sentences = json['sentences'] as List?;

        deckFiles.add({
          'path': path,
          'categories': categories,
          'difficulty': difficulty,
          'id': json['id'],
          'name': name,
          'inputType': json['inputType'] ?? 'text',
          if (json['reverseInputType'] != null) 'reverseInputType': json['reverseInputType'],
          'wordCount': words?.length ?? 0,
          'hasSentences': sentences?.isNotEmpty ?? false,
        });

        stdout.writeln('  ✅ $name → ${categories.join(' > ')}');
```

- [ ] **Step 2: Run it**

Run: `dart run tool/generate_deck_manifest.dart`
Expected output ends with: `✨ Manifest généré avec 44 decks !`

- [ ] **Step 3: Verify the new fields are present**

Run:

```bash
python3 -c "
import json
d = json.load(open('assets/decks/manifest.json'))
e = d['decks'][0]
assert 'id' in e and 'name' in e and 'inputType' in e and 'wordCount' in e and 'hasSentences' in e, e
print('OK', e['id'], e['name'], e['wordCount'], e['hasSentences'])
"
```

Expected: prints `OK <id> <name> <count> <bool>` with no `AssertionError`.

- [ ] **Step 4: Full suite + analyze**

Run: `flutter analyze` — expect: No issues found!
Run: `flutter test` — expect: all pass (the regenerated `manifest.json` doesn't break any existing test; nothing reads its new fields yet).

- [ ] **Step 5: Commit**

```bash
git add tool/generate_deck_manifest.dart assets/decks/manifest.json
git commit -m "feat: emit content-summary fields in the deck manifest generator"
```

---

### Task 5: Write and run the Supabase seed script

**Files:**
- Create: `tool/seed_supabase_decks.dart`

**Interfaces:**
- Consumes: the 44 source JSON files under `assets/decks/` (unchanged by this plan — they stay as the authoring/source format).
- Produces: populated rows in Supabase's `decks` table, consumed by Task 11's end-to-end verification and, from then on, by the real app.

- [ ] **Step 1: Write the script**

Create `tool/seed_supabase_decks.dart`:

```dart
import 'dart:convert';
import 'dart:io';

const supabaseUrl = 'https://wkqzhtwzumdgeqdiriwl.supabase.co';

/// One-off/dev tool: pushes every source deck's word/sentence content to
/// Supabase's `decks` table. Run whenever a deck is added or edited.
///
/// Requires the service_role key (Project Settings > API > service_role in
/// the Supabase dashboard) -- a real secret, never hardcoded here:
///
///   SUPABASE_SERVICE_ROLE_KEY=xxx dart run tool/seed_supabase_decks.dart
void main() async {
  final serviceRoleKey = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];
  if (serviceRoleKey == null || serviceRoleKey.isEmpty) {
    stderr.writeln('❌ SUPABASE_SERVICE_ROLE_KEY environment variable is not set.');
    stderr.writeln('   Get it from Project Settings > API > service_role in the Supabase dashboard.');
    stderr.writeln('   Run: SUPABASE_SERVICE_ROLE_KEY=xxx dart run tool/seed_supabase_decks.dart');
    exit(1);
  }

  final decksDir = Directory('assets/decks');
  final client = HttpClient();
  var seeded = 0;
  var failed = 0;

  await for (final entity in decksDir.list(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.json') || entity.path.endsWith('manifest.json')) {
      continue;
    }

    try {
      final json = jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
      final id = json['id'] as String;
      final content = {
        'words': json['words'],
        'sentences': json['sentences'] ?? [],
      };

      final request = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/decks'));
      request.headers.set('apikey', serviceRoleKey);
      request.headers.set('Authorization', 'Bearer $serviceRoleKey');
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Prefer', 'resolution=merge-duplicates');
      request.add(utf8.encode(jsonEncode({'id': id, 'content': content})));

      final response = await request.close();
      await response.drain<void>();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        stdout.writeln('✅ $id');
        seeded++;
      } else {
        stderr.writeln('❌ $id -> HTTP ${response.statusCode}');
        failed++;
      }
    } catch (e) {
      stderr.writeln('❌ Error seeding ${entity.path}: $e');
      failed++;
    }
  }

  client.close();
  stdout.writeln('\n✨ Seeded $seeded deck(s), $failed failure(s).');
  if (failed > 0) exit(1);
}
```

- [ ] **Step 2: Run it**

Ask the project owner for the `service_role` key if you don't have it in the current environment (Project Settings > API > service_role in the Supabase dashboard — this is a real secret, handle it like one: don't print it, don't put it in a committed file).

Run: `SUPABASE_SERVICE_ROLE_KEY=<the key> dart run tool/seed_supabase_decks.dart`
Expected output ends with: `✨ Seeded 44 deck(s), 0 failure(s).`

- [ ] **Step 3: Verify from the public (anon) side**

Run:

```bash
curl -s "https://wkqzhtwzumdgeqdiriwl.supabase.co/rest/v1/decks?select=id&limit=5" \
  -H "apikey: sb_publishable_JXiHimDlvvOxCWVFfP0N6g_XUWj-OsM" \
  -H "Authorization: Bearer sb_publishable_JXiHimDlvvOxCWVFfP0N6g_XUWj-OsM"
```

Expected: a JSON array of 5 `{"id": "..."}` objects (not empty, not an error).

- [ ] **Step 4: Commit**

```bash
git add tool/seed_supabase_decks.dart
git commit -m "feat: add Supabase deck content seed script"
```

---

### Task 6: `DeckRepository` — on-demand content download + local cache

**Files:**
- Modify: `lib/data/repositories/deck_repository.dart`
- Modify: `test/data/repositories/deck_repository_test.dart`

**Interfaces:**
- Consumes: `Deck.toJson()`/`Deck.fromJson()`, `StorageHelper.getJson`/`saveJson` (both already exist).
- Produces: `DeckRepository({Future<Map<String, dynamic>?> Function(String deckId)? fetchDeckContent})` constructor (default hits real Supabase); `Future<Deck> downloadDeckContent(Deck metadataOnlyDeck)`, consumed by Task 8's `DeckProvider`.

- [ ] **Step 1: Write the failing tests**

In `test/data/repositories/deck_repository_test.dart`, add (near the other groups, after the `DeckRepository - custom decks` group):

```dart
  group('DeckRepository - downloadDeckContent', () {
    Deck metadataOnlyDeck() => Deck(
          id: 'deck1',
          name: 'Test Deck',
          type: DeckType.base,
          inputType: InputType.text,
          words: [],
        );

    test('merges fetched content into the metadata-only deck and caches it', () async {
      final repo = DeckRepository(
        fetchDeckContent: (id) async => {
          'words': [
            {'id': 'w1', 'prompt': 'un', 'answer': 'one'},
          ],
          'sentences': [],
        },
      );

      final populated = await repo.downloadDeckContent(metadataOnlyDeck());

      expect(populated.words.length, 1);
      expect(populated.words.first.id, 'w1');
      expect(populated.name, 'Test Deck');
    });

    test('throws when the server has no content for that deck id', () async {
      final repo = DeckRepository(fetchDeckContent: (id) async => null);

      expect(() => repo.downloadDeckContent(metadataOnlyDeck()), throwsException);
    });

    test('a downloaded deck is cached and returned by loadBaseDecks on a later call', () async {
      var fetchCount = 0;
      final firstRepo = DeckRepository(
        fetchDeckContent: (id) async {
          fetchCount++;
          return {
            'words': [
              {'id': 'w1', 'prompt': 'un', 'answer': 'one'},
            ],
            'sentences': [],
          };
        },
      );

      final decks = await firstRepo.loadBaseDecks();
      final target = decks.first;
      await firstRepo.downloadDeckContent(target);
      expect(fetchCount, 1);

      // Simulate a fresh app launch: new repository instance, same local storage.
      final secondRepo = DeckRepository();
      final reloaded = await secondRepo.loadBaseDecks();
      final reloadedTarget = reloaded.firstWhere((d) => d.id == target.id);

      expect(reloadedTarget.words.length, 1);
    });
  });
```

Add the `Word` import at the top of the file if not already present:

```dart
import 'package:language_learning_app/data/models/word.dart';
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/data/repositories/deck_repository_test.dart`
Expected: FAIL — `DeckRepository` has no named `fetchDeckContent` parameter and no `downloadDeckContent` method.

- [ ] **Step 3: Implement**

In `lib/data/repositories/deck_repository.dart`, add the import:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
```

Change the class's field declarations and add a constructor (replace the current `class DeckRepository {` opening block through the existing field declarations):

```dart
class DeckRepository {
  List<Deck>? _cachedBaseDecks;
  DeckManifest? _manifest;
  Map<String, List<Deck>>? _decksByCategory;
  Map<String, DeckEntry>? _deckMetadata;

  final Future<Map<String, dynamic>?> Function(String deckId) fetchDeckContent;

  DeckRepository({
    Future<Map<String, dynamic>?> Function(String deckId)? fetchDeckContent,
  }) : fetchDeckContent = fetchDeckContent ?? _defaultFetchDeckContent;

  static Future<Map<String, dynamic>?> _defaultFetchDeckContent(String deckId) async {
    final row = await Supabase.instance.client
        .from('decks')
        .select('content')
        .eq('id', deckId)
        .maybeSingle();
    return row?['content'] as Map<String, dynamic>?;
  }
```

Add these two new methods right after `loadBaseDecks()` (before `_organizeDecksByCategory`):

```dart
  /// Récupère le contenu (mots/phrases) d'un deck de base depuis Supabase,
  /// le fusionne dans le deck (métadonnées seules) fourni, met le résultat
  /// en cache local, et le renvoie.
  Future<Deck> downloadDeckContent(Deck metadataOnlyDeck) async {
    final content = await fetchDeckContent(metadataOnlyDeck.id);
    if (content == null) {
      throw Exception('Deck content not found on server: ${metadataOnlyDeck.id}');
    }

    final populated = Deck.fromJson({
      ...metadataOnlyDeck.toJson(),
      'words': content['words'],
      'sentences': content['sentences'] ?? [],
    });

    await StorageHelper.saveJson('downloaded_deck_${populated.id}', populated.toJson());
    return populated;
  }

  Future<Deck?> _loadCachedDeckContent(String deckId) async {
    final json = StorageHelper.getJson('downloaded_deck_$deckId');
    if (json == null) return null;
    try {
      return Deck.fromJson(json);
    } catch (e) {
      debugPrint('❌ Erreur lecture cache deck ($deckId), ignoré: $e');
      return null;
    }
  }
```

- [ ] **Step 4: Run it to verify it passes**

Run: `flutter test test/data/repositories/deck_repository_test.dart`
Expected: PASS. (The third test, exercising `loadBaseDecks()`, will only fully pass once Task 7 rewrites `loadBaseDecks()` to check the cache — if it fails at this step because `loadBaseDecks()` doesn't consult `_loadCachedDeckContent` yet, that's expected; leave it failing and continue, Task 7 makes it pass. Note this explicitly when handing off this task.)

- [ ] **Step 5: Analyze**

Run: `flutter analyze` — expect: No issues found!

- [ ] **Step 6: Commit**

```bash
git add lib/data/repositories/deck_repository.dart test/data/repositories/deck_repository_test.dart
git commit -m "feat: DeckRepository downloads and caches deck content on demand"
```

---

### Task 7: `DeckRepository.loadBaseDecks` — build decks from the manifest only

**Files:**
- Modify: `lib/data/repositories/deck_repository.dart`

**Interfaces:**
- Consumes: `DeckEntry` fields from Task 3, `_loadCachedDeckContent` from Task 6.
- Produces: `loadBaseDecks()` returns `Deck` objects with content already merged in for anything previously downloaded, and empty `words`/`sentences` otherwise — consumed by `DeckProvider`, `DeckCard`, home screen (all downstream, unchanged interface).

- [ ] **Step 1: Replace `loadBaseDecks()`**

Replace the current `loadBaseDecks()` method body in `lib/data/repositories/deck_repository.dart`:

```dart
  Future<List<Deck>> loadBaseDecks() async {
    if (_cachedBaseDecks != null) return _cachedBaseDecks!;

    try {
      final decks = <Deck>[];
      final manifestJson = await rootBundle.loadString('assets/decks/manifest.json');
      final manifestData = jsonDecode(manifestJson) as Map<String, dynamic>;
      _manifest = DeckManifest.fromJson(manifestData);

      for (final entry in _manifest!.decks) {
        final cached = await _loadCachedDeckContent(entry.id);
        decks.add(cached ??
            Deck(
              id: entry.id,
              name: entry.name,
              type: DeckType.base,
              inputType: entry.inputType,
              reverseInputType: entry.reverseInputType,
              words: [],
              sentences: [],
            ));
      }

      _cachedBaseDecks = decks;
      _organizeDecksByCategory(decks);
      _buildMetadataMap(decks);
      return decks;
    } catch (e) {
      debugPrint('💥 Erreur chargement base decks: $e');
      return [];
    }
  }
```

- [ ] **Step 2: Run the previously-pending test to verify it now passes**

Run: `flutter test test/data/repositories/deck_repository_test.dart`
Expected: PASS, including `'a downloaded deck is cached and returned by loadBaseDecks on a later call'`.

- [ ] **Step 3: Full suite + analyze**

Run: `flutter analyze` — expect: No issues found!
Run: `flutter test` — expect: all pass. (`DeckProvider`'s existing usage of `loadBaseDecks()` is unaffected — same return type, same list of `Deck`s, just built differently.)

- [ ] **Step 4: Commit**

```bash
git add lib/data/repositories/deck_repository.dart
git commit -m "refactor: build base decks from the manifest instead of per-file asset reads"
```

---

### Task 8: `DeckProvider` — make `selectDeck` download-aware

**Files:**
- Modify: `lib/providers/deck_provider.dart`
- Create: `test/providers/deck_provider_test.dart`

**Interfaces:**
- Consumes: `DeckRepository({fetchDeckContent})`, `DeckRepository.downloadDeckContent(Deck)` from Task 6.
- Produces: `DeckProvider({DeckRepository? repository})` constructor; `bool isDownloadingDeck(String deckId)`; `String? get downloadError`; `selectDeck` now downloads a base deck's content on first selection — consumed by Task 9 (`DeckCard`).

- [ ] **Step 1: Write the failing tests**

Create `test/providers/deck_provider_test.dart`:

```dart
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:language_learning_app/providers/deck_provider.dart';
import 'package:language_learning_app/data/repositories/deck_repository.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/data/models/word.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';

Deck metadataOnlyDeck() => Deck(
      id: 'deck1',
      name: 'Test Deck',
      type: DeckType.base,
      inputType: InputType.text,
      words: [],
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageHelper.init();
  });

  group('DeckProvider.selectDeck', () {
    test('downloads content for a base deck with no content yet, then selects it', () async {
      final repo = DeckRepository(
        fetchDeckContent: (id) async => {
          'words': [
            {'id': 'w1', 'prompt': 'un', 'answer': 'one'},
          ],
          'sentences': [],
        },
      );
      final provider = DeckProvider(repository: repo);

      await provider.selectDeck(metadataOnlyDeck());

      expect(provider.selectedDeck?.words.length, 1);
      expect(provider.isDownloadingDeck('deck1'), isFalse);
      expect(provider.downloadError, isNull);
    });

    test('sets isDownloadingDeck while the fetch is in flight, clears it after', () async {
      final completer = Completer<Map<String, dynamic>?>();
      final repo = DeckRepository(fetchDeckContent: (id) => completer.future);
      final provider = DeckProvider(repository: repo);

      final future = provider.selectDeck(metadataOnlyDeck());
      expect(provider.isDownloadingDeck('deck1'), isTrue);

      completer.complete({'words': [], 'sentences': []});
      await future;

      expect(provider.isDownloadingDeck('deck1'), isFalse);
    });

    test('surfaces an error and leaves selectedDeck unset when the download fails', () async {
      final repo = DeckRepository(fetchDeckContent: (id) async => null);
      final provider = DeckProvider(repository: repo);

      await provider.selectDeck(metadataOnlyDeck());

      expect(provider.selectedDeck, isNull);
      expect(provider.downloadError, isNotNull);
      expect(provider.isDownloadingDeck('deck1'), isFalse);
    });

    test('selects a custom deck synchronously without attempting a download', () async {
      final repo = DeckRepository(
        fetchDeckContent: (id) async => throw Exception('should not be called for a custom deck'),
      );
      final provider = DeckProvider(repository: repo);
      final customDeck = Deck(
        id: 'custom1',
        name: 'Custom',
        type: DeckType.custom,
        inputType: InputType.text,
        words: [Word(id: 'w1', prompt: 'a', answer: 'b')],
      );

      await provider.selectDeck(customDeck);

      expect(provider.selectedDeck?.id, 'custom1');
    });

    test('selects a base deck with content already loaded synchronously, no download', () async {
      final repo = DeckRepository(
        fetchDeckContent: (id) async => throw Exception('should not be called, already has content'),
      );
      final provider = DeckProvider(repository: repo);
      final alreadyLoaded = Deck(
        id: 'deck1',
        name: 'Test Deck',
        type: DeckType.base,
        inputType: InputType.text,
        words: [Word(id: 'w1', prompt: 'un', answer: 'one')],
      );

      await provider.selectDeck(alreadyLoaded);

      expect(provider.selectedDeck?.id, 'deck1');
    });
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/providers/deck_provider_test.dart`
Expected: FAIL — `DeckProvider` has no `repository` named constructor parameter, no `isDownloadingDeck`, no `downloadError`.

- [ ] **Step 3: Implement**

Replace the top of `lib/providers/deck_provider.dart` (field declarations through the getters):

```dart
class DeckProvider extends ChangeNotifier {
  final DeckRepository _repository;

  DeckProvider({DeckRepository? repository}) : _repository = repository ?? DeckRepository();

  List<Deck> _baseDecks = [];
  List<Deck> _customDecks = [];
  Deck? _selectedDeck;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _downloadingDeckId;
  String? _downloadError;

  // Getters
  List<Deck> get baseDecks => _baseDecks;
  List<Deck> get customDecks => _customDecks;
  List<Deck> get allDecks => [..._baseDecks, ..._customDecks];
  Deck? get selectedDeck => _selectedDeck;
  bool get isLoading => _isLoading;
  DeckRepository get repository => _repository;
  bool get isInitialized => _isInitialized;
  bool isDownloadingDeck(String deckId) => _downloadingDeckId == deckId;
  String? get downloadError => _downloadError;
```

Replace the `selectDeck` method:

```dart
  /// Sélectionne un deck pour l'utiliser dans les jeux. Si c'est un deck de
  /// base sans contenu chargé/en cache, télécharge son contenu depuis
  /// Supabase avant de le sélectionner.
  Future<void> selectDeck(Deck deck) async {
    final needsDownload = deck.type == DeckType.base && deck.words.isEmpty && deck.sentences.isEmpty;

    if (!needsDownload) {
      _selectedDeck = deck;
      await _repository.saveSelectedDeckId(deck.id);
      debugPrint('✅ Deck sélectionné: ${deck.name}');
      notifyListeners();
      return;
    }

    _downloadingDeckId = deck.id;
    _downloadError = null;
    notifyListeners();

    try {
      final populated = await _repository.downloadDeckContent(deck);
      final index = _baseDecks.indexWhere((d) => d.id == populated.id);
      if (index != -1) _baseDecks[index] = populated;

      _selectedDeck = populated;
      await _repository.saveSelectedDeckId(populated.id);
      debugPrint('✅ Deck téléchargé et sélectionné: ${populated.name}');
    } catch (e) {
      _downloadError = e.toString();
      debugPrint('❌ Erreur téléchargement deck ${deck.id}: $e');
    } finally {
      _downloadingDeckId = null;
      notifyListeners();
    }
  }
```

- [ ] **Step 4: Run it to verify it passes**

Run: `flutter test test/providers/deck_provider_test.dart`
Expected: PASS.

- [ ] **Step 5: Full suite + analyze**

Run: `flutter analyze` — expect: No issues found!
Run: `flutter test` — expect: all pass.

- [ ] **Step 6: Commit**

```bash
git add lib/providers/deck_provider.dart test/providers/deck_provider_test.dart
git commit -m "feat: DeckProvider downloads a base deck's content on first selection"
```

---

### Task 9: `DeckCard` — reflect manifest metadata and download/loading states

**Files:**
- Modify: `lib/screens/decks/widgets/deck_card.dart`

**Interfaces:**
- Consumes: `DeckEntry.wordCount`/`hasSentences` (Task 3), `DeckProvider.isDownloadingDeck` (Task 8).
- Produces: no new public interface — this is a leaf UI widget.

- [ ] **Step 1: Update the word-count display and add download/loading state**

In `lib/screens/decks/widgets/deck_card.dart`, replace the `build` method's start (through where `metadata` is computed) and the word-count `Text`:

```dart
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final deckProvider = context.watch<DeckProvider>();
    final isSelected = deckProvider.selectedDeck?.id == deck.id;
    final metadata = isBase ? deckProvider.repository.getDeckMetadata(deck.id) : null;
    final needsDownload = isBase && deck.words.isEmpty && deck.sentences.isEmpty;
    final isDownloading = deckProvider.isDownloadingDeck(deck.id);
    final wordCount = isBase && metadata != null ? metadata.wordCount : deck.totalWords;
```

Replace the word-count `Text` widget:

```dart
                            Text(
                              l10n.totalWords(deck.totalWords),
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
```

with:

```dart
                            Text(
                              l10n.totalWords(wordCount),
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
```

Replace the `_buildDeckIcon(isSelected)` call in `build` with `_buildDeckIcon(isSelected, needsDownload, isDownloading)`, and replace `_buildDeckIcon` itself:

```dart
  Widget _buildDeckIcon(bool isSelected, bool needsDownload, bool isDownloading) {
    final icon = isDownloading
        ? null
        : needsDownload
            ? Icons.cloud_download_outlined
            : (deck.inputType == InputType.text ? Icons.keyboard : Icons.draw);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.2)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: isDownloading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isSelected ? AppColors.primary : Colors.grey.shade600,
              ),
            )
          : Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.grey.shade600,
              size: 20,
            ),
    );
  }
```

- [ ] **Step 2: Fix `_selectDeck` in `DecksScreen` — it currently passes the pre-download deck to `GameProvider`**

`lib/screens/decks/decks_screen.dart` has one shared `_selectDeck(context, deck)` helper (used by both the base-deck and custom-deck `DeckCard`s via `onTap: () => _selectDeck(context, deck)`, lines 186 and 264). Today it does:

```dart
void _selectDeck(BuildContext context, Deck deck) async {
  final deckProvider = context.read<DeckProvider>();
  await deckProvider.selectDeck(deck);

  if (context.mounted) {
    context.read<GameProvider>().setDeck(deck);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.deckSelected(deck.localizedName(context))),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
```

This is a real bug once base decks can need a download: `context.read<GameProvider>().setDeck(deck)` passes the *original* `deck` parameter — for an undownloaded base deck, that's the empty, metadata-only stub, not the populated deck `deckProvider.selectDeck` just fetched. The game screen would open with zero words even though the download succeeded. It also always shows the "deck selected" success snackbar, even when the download failed.

Replace it with:

```dart
void _selectDeck(BuildContext context, Deck deck) async {
  final deckProvider = context.read<DeckProvider>();
  await deckProvider.selectDeck(deck);

  if (!context.mounted) return;

  final error = deckProvider.downloadError;
  if (error != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.deckDownloadFailed),
        backgroundColor: AppColors.error,
      ),
    );
    return;
  }

  final selected = deckProvider.selectedDeck!;
  context.read<GameProvider>().setDeck(selected);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(AppLocalizations.of(context)!.deckSelected(selected.localizedName(context))),
      duration: const Duration(seconds: 1),
    ),
  );
}
```

(`AppColors` is already imported in this file.) Add a new l10n key `deckDownloadFailed` to all four ARB files (`lib/l10n/app_en.arb`, `app_fr.arb`, `app_es.arb`, `app_it.arb`), following the existing pattern (near `resetDeckMessage`/similar short user-facing strings):

- `app_en.arb`: `"deckDownloadFailed": "Couldn't download this deck. Check your connection and try again.",`
- `app_fr.arb`: `"deckDownloadFailed": "Impossible de télécharger ce deck. Vérifie ta connexion et réessaie.",`
- `app_es.arb`: `"deckDownloadFailed": "No se pudo descargar este mazo. Comprueba tu conexión e inténtalo de nuevo.",`
- `app_it.arb`: `"deckDownloadFailed": "Impossibile scaricare questo mazzo. Controlla la connessione e riprova.",`

Run: `flutter gen-l10n`

- [ ] **Step 3: Full suite + analyze**

Run: `flutter analyze` — expect: No issues found!
Run: `flutter test` — expect: all pass.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/decks/widgets/deck_card.dart lib/screens/decks/decks_screen.dart lib/l10n/
git commit -m "feat: DeckCard shows download/loading state and word count from manifest"
```

---

### Task 10: Home screen — fix Sentence-mode availability for undownloaded decks

**Files:**
- Modify: `lib/screens/home/home_screen.dart`

**Interfaces:**
- Consumes: `DeckEntry.hasSentences` (Task 3) via `DeckProvider.repository.getDeckMetadata`.
- Produces: no new public interface.

- [ ] **Step 1: Fix the availability check**

In `lib/screens/home/home_screen.dart`, find:

```dart
    final selectedDeck = context.watch<DeckProvider>().selectedDeck;
    final isUnavailable = mode.type == GameType.sentence && (selectedDeck?.sentences.isEmpty ?? false);
```

Replace with:

```dart
    final deckProvider = context.watch<DeckProvider>();
    final selectedDeck = deckProvider.selectedDeck;
    final hasSentences = selectedDeck == null
        ? false
        : selectedDeck.type == DeckType.custom
            ? selectedDeck.sentences.isNotEmpty
            : (deckProvider.repository.getDeckMetadata(selectedDeck.id)?.hasSentences ?? false);
    final isUnavailable = mode.type == GameType.sentence && !hasSentences;
```

Add the `DeckType` import if not already present:

```dart
import 'package:language_learning_app/data/models/deck.dart';
```

- [ ] **Step 2: Full suite + analyze**

Run: `flutter analyze` — expect: No issues found!
Run: `flutter test` — expect: all pass.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/home/home_screen.dart
git commit -m "fix: Sentence mode availability reads manifest hasSentences for base decks"
```

---

### Task 11: Stop bundling deck content; end-to-end verification

**Files:**
- Modify: `pubspec.yaml`

**Interfaces:**
- Consumes: everything from Tasks 1–10.
- Produces: the shipped app no longer contains the 44 decks' word/sentence JSON; final proof the whole chain (manifest → download → cache) works against the real Supabase project.

- [ ] **Step 1: Trim the asset list**

In `pubspec.yaml`, replace the `assets:` block:

```yaml
  # Assets
  assets:
    - assets/decks/
    - assets/decks/chinese/
    - assets/decks/chinese/hsk1/
    - assets/decks/chinese/hsk1/part1-5/
    - assets/decks/chinese/hsk1/part6-10/
    - assets/decks/chinese/hsk1/part11-15/
    - assets/decks/english/a2_key/
```

with:

```yaml
  # Assets
  assets:
    - assets/decks/manifest.json
```

Run: `flutter pub get`

- [ ] **Step 2: Full suite + analyze**

Run: `flutter analyze` — expect: No issues found!
Run: `flutter test` — expect: all pass (the `loadBaseDecks()` tests in Task 6/7 only need `manifest.json`, still bundled).

- [ ] **Step 3: End-to-end verification against the real Supabase project**

This is the one runnable check that exercises the real network path (everything else is fake-injected in tests). Confirm Task 1's table is provisioned and Task 5's seed has run, then:

```bash
cat > /tmp/e2e_check.dart << 'EOF'
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:language_learning_app/core/config/supabase_config.dart';
import 'package:language_learning_app/data/repositories/deck_repository.dart';
import 'package:language_learning_app/data/models/deck.dart';

void main() {
  test('downloadDeckContent fetches a real deck from the live Supabase project', () async {
    await Supabase.initialize(url: SupabaseConfig.url, anonKey: SupabaseConfig.anonKey);
    final repo = DeckRepository();
    final decks = await repo.loadBaseDecks();
    expect(decks, isNotEmpty);

    final target = decks.first;
    final populated = await repo.downloadDeckContent(target);

    expect(populated.words, isNotEmpty);
  });
}
EOF
flutter test /tmp/e2e_check.dart
rm /tmp/e2e_check.dart
```

Expected: PASS — a real network round-trip to Supabase returns real word content for a real deck id. If this fails, check (in order): Task 1's RLS policy, Task 5's seed actually ran, `SupabaseConfig` values match the real project.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: stop bundling deck content JSON, catalog + downloads only"
```
