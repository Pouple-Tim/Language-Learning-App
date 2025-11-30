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

# Configurer l'USB dynamiquement (WSL2 Fix)
usb:
	@echo "D'abord lancer la liaison depuis powershell"
	@echo "usbipd list => usbipd attach --wsl --busid [BUSID]"
	@echo "🔌 Démarrage du service udev..."
	@sudo service udev start
	@echo "👀 Recherche du périphérique connecté (hors hubs)..."
	@# On récupère la ligne qui n'est pas un 'root hub' et on prend la colonne ID (ex: 22d9:2769)
	@id_str=$$(lsusb | grep -v "root hub" | head -n 1 | awk '{print $$6}'); \
	if [ -z "$$id_str" ]; then \
		echo "❌ Aucun périphérique trouvé ! Avez-vous fait 'usbipd attach' sous Windows ?"; \
		exit 1; \
	fi; \
	vendor=$$(echo $$id_str | cut -d':' -f1); \
	product=$$(echo $$id_str | cut -d':' -f2); \
	echo "🔍 Périphérique détecté : Vendor=$$vendor, Product=$$product"; \
	echo "✍️  Mise à jour des règles udev..."; \
	echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="'$$vendor'", ATTR{idProduct}=="'$$product'", MODE="0666", GROUP="plugdev"' | sudo tee /etc/udev/rules.d/51-android.rules > /dev/null
	@echo "🔄 Application des nouvelles règles..."
	@sudo udevadm control --reload-rules
	@sudo udevadm trigger
	@echo "🔁 Redémarrage serveur ADB..."
	@adb kill-server
	@adb start-server
	@echo "📱 ADB Devices :"
	@adb devices
	@echo "🚀 Flutter Devices :"
	@flutter devices