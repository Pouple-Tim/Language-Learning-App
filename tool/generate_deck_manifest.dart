import 'dart:io';
import 'dart:convert';

void main() async {
  print('🔍 Scanning decks...');

  final decksDir = Directory('assets/decks');
  final deckFiles = <Map<String, dynamic>>[];

  // Scanner récursivement tous les fichiers JSON
  await for (final entity in decksDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.json') && !entity.path.endsWith('manifest.json')) {
      try {
        // Lire le fichier JSON
        final content = await entity.readAsString();
        final json = jsonDecode(content);

        // Extraire les informations
        final path = entity.path.replaceAll('\\', '/');
        final name = json['name'] ?? 'Unknown';
        
        // Extraire le chemin relatif depuis assets/decks/
        final relativePath = path.replaceAll('assets/decks/', '');
        final pathParts = relativePath.split('/');
        pathParts.removeLast(); // Enlever le nom du fichier
        
        // Le path devient la hiérarchie : categories = pathParts
        // Ex: [] = racine (Autres), ['chinese'] = catégorie, ['chinese', 'hsk1'] = catégorie + sous-cat
        final categories = pathParts.map((part) => _capitalize(part)).toList();
        
        // 👇 AJOUTER : Si pas de catégorie, mettre dans "Autres"
        if (categories.isEmpty) {
          categories.add('Autres');
        }
        
        print('  📁 $relativePath → categories: $categories');

        // Déduire la difficulté
        String difficulty = 'beginner';
        final lowerName = name.toLowerCase();
        final lowerPath = path.toLowerCase();
        
        if (lowerName.contains('hsk2') || lowerPath.contains('hsk2')) {
          difficulty = 'intermediate';
        } else if (lowerName.contains('hsk3') || lowerPath.contains('hsk3')) {
          difficulty = 'advanced';
        }

        deckFiles.add({
          'path': path,
          'categories': categories, // 👈 Liste de catégories hiérarchiques
          'difficulty': difficulty,
        });

        print('  ✅ $name → ${categories.join(' > ')}');
      } catch (e) {
        print('  ❌ Error reading ${entity.path}: $e');
      }
    }
  }

  // Trier par catégories (hiérarchique)
  deckFiles.sort((a, b) {
    final aCats = a['categories'] as List;
    final bCats = b['categories'] as List;
    
    // Comparer niveau par niveau
    for (int i = 0; i < aCats.length && i < bCats.length; i++) {
      final compare = aCats[i].compareTo(bCats[i]);
      if (compare != 0) return compare;
    }
    
    // Si tous les niveaux sont égaux, le plus court en premier
    return aCats.length.compareTo(bCats.length);
  });

  // Générer le manifest
  final manifest = {
    'version': '1.0.0',
    'lastUpdate': DateTime.now().toIso8601String().split('T')[0],
    'decks': deckFiles,
  };

  // Écrire le fichier manifest.json
  final manifestFile = File('assets/decks/manifest.json');
  await manifestFile.writeAsString(
    JsonEncoder.withIndent('  ').convert(manifest),
  );

  print('\n✨ Manifest généré avec ${deckFiles.length} decks !');
  print('📄 Fichier: ${manifestFile.path}');
}

String _capitalize(String text) {
  if (text.isEmpty) return text;
  
  // Mapping des noms de dossiers
  final mapping = {
    'japanese': 'Japonais',
    'chinese': 'Chinois',
    'korean': 'Coréen',
    'spanish': 'Espagnol',
    'french': 'Français',
    'german': 'Allemand',
    'italian': 'Italien',
    // Pour les sous-dossiers
    'hsk1': 'HSK 1',
    'hsk2': 'HSK 2',
    'hsk3': 'HSK 3',
    'part1-5': 'Parties 1 à 5',
    'part6-10': 'Parties 6 à 10',
    'part11-15': 'Parties 11 à 15',
    'part16-20': 'Parties 16 à 20',
    'test': 'Test',
    'basics': 'Basique',
    'advanced': 'Avancé',
  };
  
  return mapping[text.toLowerCase()] ?? _formatDefault(text);
}

String _formatDefault(String text) {
  // Remplacer _ et - par des espaces
  text = text.replaceAll('_', ' ').replaceAll('-', ' ');
  
  // Capitaliser chaque mot
  return text.split(' ').map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}