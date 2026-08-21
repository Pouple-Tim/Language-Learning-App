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
