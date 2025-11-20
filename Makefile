.PHONY: generate-manifest generate-l10n build run clean add-deck

# Générer les fichiers de localisation
generate-l10n:
	@echo "🌍 Génération des fichiers de localisation..."
	@flutter gen-l10n
	@echo "✅ Fichiers de localisation générés !"

# Générer le manifest automatiquement
generate-manifest:
	@echo "🔄 Génération du manifest..."
	@dart run tool/generate_deck_manifest.dart
	@echo "✅ Manifest généré !"

# Build avec génération du manifest et l10n
build: generate-l10n generate-manifest
	@echo "📦 Building app..."
	@flutter pub get
	@dart run build_runner build --delete-conflicting-outputs
	@echo "✅ Build terminé !"

# Lancer l'app avec manifest et l10n à jour
run: generate-l10n generate-manifest
	@flutter run

# Nettoyer
clean:
	@flutter clean
	@rm -f assets/decks/manifest.json
	@rm -rf .dart_tool/flutter_gen
	@echo "🧹 Nettoyé !"

# Ajouter un nouveau deck (helper)
add-deck:
	@echo "📝 Créez votre fichier JSON dans assets/decks/"
	@echo "Puis lancez: make generate-manifest"

# Régénérer seulement les traductions (utile pendant le développement)
l10n: generate-l10n
	@echo "🎉 Traductions mises à jour !"

# Tout régénérer (manifest + l10n)
generate: generate-l10n generate-manifest
	@echo "🎉 Tout a été régénéré !"