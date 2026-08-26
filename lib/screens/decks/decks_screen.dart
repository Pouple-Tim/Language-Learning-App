import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:language_learning_app/providers/deck_provider.dart';
import 'package:language_learning_app/providers/game_provider.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';
import 'package:language_learning_app/core/extensions/deck_extensions.dart';

// Imports des modules séparés
import 'deck_editor_screen.dart';
import 'widgets/deck_card.dart';
import 'widgets/deck_preview_sheet.dart';
import 'package:language_learning_app/core/utils/deck_hierarchy_utils.dart';
import 'package:language_learning_app/core/tutorial/tutorial_service.dart';
import 'package:language_learning_app/core/tutorial/tutorial_coach_mark_helper.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class DecksScreen extends StatefulWidget {
  const DecksScreen({super.key});

  @override
  State<DecksScreen> createState() => _DecksScreenState();
}

class _DecksScreenState extends State<DecksScreen> {
  // Sets pour garder en mémoire quels accordéons sont ouverts
  final Set<String> _expandedNodes = {};

  final GlobalKey _decksListKey = GlobalKey();
  final GlobalKey _createDeckKey = GlobalKey();
  VoidCallback? _decksLoadListener;

  @override
  void initState() {
    super.initState();
    // Auto-expand the first category so the hierarchy tour step has a
    // concrete, already-open example to point at instead of an all-collapsed
    // list. Must happen before the first build (not via setState afterwards,
    // since ExpansionTile only reads `initiallyExpanded` once) and only when
    // the tour is about to show, so regular visits keep everything collapsed.
    if (!TutorialService.hasSeenDecks()) {
      final deckProvider = context.read<DeckProvider>();
      if (!deckProvider.isLoading) {
        _autoExpandFirstCategoryForTour(deckProvider);
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowDecksTour());
  }

  void _autoExpandFirstCategoryForTour(DeckProvider deckProvider) {
    final hierarchy = DeckHierarchyUtils.buildHierarchyMap(deckProvider);
    final topKeys = hierarchy.keys.where((key) => key != '_decks').toList()..sort();
    if (topKeys.isNotEmpty) {
      _expandedNodes.add(topKeys.first);
    }
  }

  @override
  void dispose() {
    final listener = _decksLoadListener;
    if (listener != null) {
      context.read<DeckProvider>().removeListener(listener);
    }
    super.dispose();
  }

  void _maybeShowDecksTour() {
    if (!mounted || TutorialService.hasSeenDecks()) return;

    final deckProvider = context.read<DeckProvider>();
    if (deckProvider.isLoading) {
      _decksLoadListener = () {
        if (!deckProvider.isLoading) {
          deckProvider.removeListener(_decksLoadListener!);
          _decksLoadListener = null;
          _maybeShowDecksTour();
        }
      };
      deckProvider.addListener(_decksLoadListener!);
      return;
    }

    // Wait for a real completed frame before measuring target rects -- this
    // may run from a provider listener fired mid-rebuild (see
    // _measureTarget's doc comment in tutorial_coach_mark_helper.dart).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      TutorialService.markDecksSeen();
      showTutorial(
        context: context,
        skipLabel: l10n.tutorialSkipButton,
        targets: [
          buildTutorialTarget(
            identify: 'decks_select',
            keyTarget: _decksListKey,
            title: l10n.tutorialDecksSelectTitle,
            description: l10n.tutorialDecksSelectDesc,
          ),
          buildTutorialTarget(
            identify: 'decks_create',
            keyTarget: _createDeckKey,
            title: l10n.tutorialDecksCreateTitle,
            description: l10n.tutorialDecksCreateDesc,
            align: ContentAlign.top,
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myDecks),
      ),
      body: Consumer<DeckProvider>(
        builder: (context, deckProvider, _) {
          if (deckProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => _handleRefresh(context),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      key: _decksListKey,
                      child: _buildBaseDecksSection(context, deckProvider),
                    ),
                    const SizedBox(height: 32),
                    _buildCustomDecksSection(context, deckProvider),
                    const SizedBox(height: 80), // Espace pour le FAB
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: _createDeckKey,
        onPressed: () => _navigateToEditor(context, null),
        icon: const Icon(Icons.add),
        label: Text(l10n.createDeck),
      ),
    );
  }

  Future<void> _handleRefresh(BuildContext context) async {
    final deckProvider = context.read<DeckProvider>();
    await deckProvider.reloadDecks();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.decksReloaded)),
    );
  }

  // --- SECTION DECKS DE BASE (HIÉRARCHIE) ---

  Widget _buildBaseDecksSection(BuildContext context, DeckProvider deckProvider) {
    final l10n = AppLocalizations.of(context)!;
    final hierarchy = DeckHierarchyUtils.buildHierarchyMap(deckProvider);

    if (hierarchy.isEmpty) {
      return _buildEmptyState(context, l10n.noDecksAvailable);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, l10n.decksAvailable, Icons.library_books),
        const SizedBox(height: 12),
        // Construction récursive
        ..._buildRecursiveHierarchy(context, hierarchy, [], 0),
      ],
    );
  }

  List<Widget> _buildRecursiveHierarchy(
    BuildContext context,
    Map<String, dynamic> node,
    List<String> path,
    int level,
  ) {
    // MODIFICATION 1 : Récupérer la luminosité pour adapter les couleurs
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    final keys = node.keys.where((k) => k != '_decks').toList()..sort();
    
    return keys.map((key) {
      final subNode = node[key] as Map<String, dynamic>;
      final decks = (subNode['_decks'] as List<Deck>?) ?? [];
      final hasSubcategories = subNode.keys.any((k) => k != '_decks');
      final totalDecks = DeckHierarchyUtils.countTotalDecks(subNode);
      
      final currentPath = [...path, key];
      final pathKey = currentPath.join('_');
      final isExpanded = _expandedNodes.contains(pathKey);

      return Padding(
        padding: EdgeInsets.only(left: level * 12.0, bottom: 8),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: isExpanded ? (level == 0 ? 4 : 2) : 1,
          // Couleur de la carte adaptée au thème si niveau > 0
          color: level > 0 
              ? (isDark ? Colors.grey[850] : Colors.grey[50]) 
              : (isDark ? Colors.grey[800] : Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: level > 0 
              ? BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300) 
              : BorderSide.none,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              key: Key(pathKey),
              
              shape: const Border(),
              collapsedShape: const Border(),
              
              initiallyExpanded: isExpanded,
              onExpansionChanged: (expanded) {
                setState(() => expanded 
                    ? _expandedNodes.add(pathKey) 
                    : _expandedNodes.remove(pathKey));
              },
              leading: _buildCategoryIcon(key, level),
              title: Text(
                translateCategory(key, context),
                style: TextStyle(
                  fontWeight: level == 0 ? FontWeight.bold : FontWeight.w600,
                  // MODIFICATION 2 : Couleur du texte dynamique
                  color: level == 0 
                      ? Theme.of(context).textTheme.titleMedium?.color 
                      : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                ),
              ),
              subtitle: Text(
                '$totalDecks ${totalDecks > 1 ? l10n.decks : l10n.deck}',
                style: TextStyle(
                  // Couleur du sous-titre dynamique
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
              children: [
                if (hasSubcategories)
                  ..._buildRecursiveHierarchy(context, subNode, currentPath, level + 1),
                
                ...decks.map((deck) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DeckCard(
                      deck: deck,
                      isBase: true,
                      onTap: () => _selectDeck(context, deck),
                      onLongPress: () => _showDeckPreview(context, deck),
                    ),
                  )),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildCategoryIcon(String name, int level) {
    if (level > 0) {
      return Container(
        width: 4,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }
    
    IconData icon;
    switch (name.toLowerCase()) {
      case 'japonais': icon = Icons.translate; break;
      case 'chinois': icon = Icons.draw; break;
      case 'coréen': icon = Icons.language; break;
      case 'espagnol': icon = Icons.public; break;
      case 'français': icon = Icons.flag; break;
      default: icon = Icons.book;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: AppColors.primary, size: 24),
    );
  }

  // --- SECTION DECKS PERSONNALISÉS ---

  Widget _buildCustomDecksSection(BuildContext context, DeckProvider deckProvider) {
    final l10n = AppLocalizations.of(context)!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(context, l10n.myDecks, Icons.create),
            IconButton(
              onPressed: () => _navigateToEditor(context, null),
              icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 32),
              tooltip: l10n.createDeck,
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (deckProvider.customDecks.isEmpty)
          _buildEmptyCustomDecks(context)
        else
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: deckProvider.customDecks
                    .map((deck) => DeckCard(
                          deck: deck,
                          isBase: false,
                          onTap: () => _selectDeck(context, deck),
                          onLongPress: () => _showDeckPreview(context, deck),
                          onEdit: (d) => _navigateToEditor(context, d),
                          onDelete: (d) => _showDeleteDialog(context, d),
                        ))
                    .toList(),
              ),
            ),
          ),
      ],
    );
  }

  // --- HELPERS GÉNÉRAUX ---

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                // Utilisation explicite de la couleur du thème pour être sûr
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        // Couleur de fond adaptée
        color: isDark ? Colors.grey[850] : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          message, 
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600
          )
        ),
      ),
    );
  }

  Widget _buildEmptyCustomDecks(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        // Couleur de fond adaptée
        color: isDark ? Colors.grey[850] : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.folder_open, 
            size: 64, 
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noCustomDecks, 
            style: TextStyle(
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade600, 
              fontSize: 16, 
              fontWeight: FontWeight.bold
            )
          ),
          const SizedBox(height: 8),
          Text(
            l10n.createFirstDeck, 
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500
            )
          ),
        ],
      ),
    );
  }

  // --- ACTIONS ---

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

  void _showDeckPreview(BuildContext context, Deck deck) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DeckPreviewSheet(deck: deck),
    );
  }

  void _navigateToEditor(BuildContext context, Deck? deck) async {
    final result = await Navigator.push<Deck>(
      context,
      MaterialPageRoute(builder: (context) => DeckEditorScreen(deck: deck)),
    );

    if (result != null && context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      final deckProvider = context.read<DeckProvider>();
      
      if (deck == null) {
        await deckProvider.addCustomDeck(result);
        if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(l10n.deckCreated(result.localizedName(context)))));
        }
      } else {
        await deckProvider.updateCustomDeck(result);
        if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(l10n.deckModified(result.localizedName(context)))));
        }
      }
    }
  }

  void _showDeleteDialog(BuildContext context, Deck deck) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteDeck),
        content: Text(l10n.deleteDeckMessage(deck.localizedName(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await context.read<DeckProvider>().deleteCustomDeck(deck.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(l10n.deckDeleted(deck.localizedName(context))),
                ));
              }
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}