# Notes pour Claude Code

## À FAIRE dans la même session qu'un ajout de fonctionnalité visible

Quand tu ajoutes / modifies une fonctionnalité que l'utilisateur voit (nouveau mode
de jeu, nouvel écran, changement de comportement notable, nouveaux decks, etc.),
mets à jour **dans la même PR / session** — pas dans une session dédiée plus tard :

1. **`README.md`**
   - section `## Ce que fait l'application` (tableau des modes, listes de features)
   - toute autre section impactée (Architecture, Modèle de données, Contenu des decks…)
   - si l'architecture d'exécution change : régénérer le diagramme
     (`docs/architecture/runtime-arch.json` → voir [[reference-archify-usage]] en mémoire)

2. **Section « À propos » de l'app**, sous-partie « Nouveautés » :
   - `lib/screens/settings/settings_screen.dart` → `_buildAboutSection` :
     ajouter un `_buildFeatureItem(<icône>, l10n.news<Nom>)`
   - clés `news<Nom>` (+ `whatsNewTitle` si besoin) dans les **4** fichiers
     `lib/l10n/app_{en,fr,es,it}.arb` (template = `app_en.arb`), puis `flutter gen-l10n`
   - garder la liste courte (~4 entrées) : retirer la plus ancienne en ajoutant la nouvelle

## Divers

- Barre de qualité avant de dire « fini » : `flutter analyze` + `flutter test`
  (pas de smoke test visuel manuel par défaut — voir mémoire).
- `develop` et `main` sont des branches git-flow permanentes : ne jamais supprimer `develop`.
- Le reste du contexte projet vit dans la mémoire auto
  (`~/.claude/projects/.../memory/MEMORY.md`).
