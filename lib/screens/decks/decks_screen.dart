import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:language_learning_app/providers/deck_provider.dart';
import 'package:language_learning_app/providers/game_provider.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/data/models/word.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'deck_editor_screen.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';
import 'package:language_learning_app/core/extensions/deck_extensions.dart';

class DecksScreen extends StatefulWidget {
  const DecksScreen({super.key});

  @override
  State<DecksScreen> createState() => _DecksScreenState();
}

class _DecksScreenState extends State<DecksScreen> {
  final Set<String> _expandedCategories = {};
  final Set<String> _expandedSubcategories = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myDecks),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _handleRefresh(context),
          ),
        ],
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
                    _buildBaseDecksByCategory(context, deckProvider),
                    const SizedBox(height: 32),
                    _buildCustomDecksSection(context, deckProvider),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToEditor(context, null),
        icon: const Icon(Icons.add),
        label: Text(l10n.createDeck),
      ),
    );
  }

  Future<void> _handleRefresh(BuildContext context) async {
    final provider = context.read<DeckProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    await provider.reloadDecks();
    
    if (!mounted) return;

    setState(() {
      _expandedCategories.clear();
      _expandedSubcategories.clear();
    });
    
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.decksReloaded)),
    );
  }

  Widget _buildBaseDecksByCategory(BuildContext context, DeckProvider deckProvider) {
    final l10n = AppLocalizations.of(context)!;
    final hierarchy = _buildHierarchyMap(deckProvider);

    if (hierarchy.isEmpty) {
      return _buildEmptyState(l10n.noDecksAvailable);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, l10n.decksAvailable, Icons.library_books),
        const SizedBox(height: 12),
        ..._buildHierarchyWidgets(context, hierarchy, [], deckProvider),
      ],
    );
  }

  Map<String, dynamic> _buildHierarchyMap(DeckProvider deckProvider) {
    final hierarchy = <String, dynamic>{};
    final repository = deckProvider.repository;
    
    for (final deck in deckProvider.baseDecks) {
      final metadata = repository.getDeckMetadata(deck.id);
      final categories = metadata?.categories ?? 
          [deck.name.split(' - ').firstOrNull ?? 'Autres'];
      
      _addToHierarchy(hierarchy, categories, deck);
    }
    
    return hierarchy;
  }

  void _addToHierarchy(Map<String, dynamic> hierarchy, List<String> categories, Deck deck) {
    if (categories.isEmpty) {
      (hierarchy['_decks'] ??= <Deck>[]).add(deck);
      return;
    }
    
    final category = categories.first;
    hierarchy[category] ??= <String, dynamic>{};
    
    if (categories.length == 1) {
      (hierarchy[category]['_decks'] ??= <Deck>[]).add(deck);
    } else {
      _addToHierarchy(hierarchy[category], categories.sublist(1), deck);
    }
  }

  List<Widget> _buildHierarchyWidgets(
    BuildContext context,
    Map<String, dynamic> node,
    List<String> path,
    DeckProvider deckProvider,
  ) {
    final keys = node.keys.where((k) => k != '_decks').toList()..sort();
    
    return keys.map((key) {
      final subNode = node[key] as Map<String, dynamic>;
      final decks = (subNode['_decks'] as List<Deck>?) ?? [];
      final hasSubcategories = subNode.keys.any((k) => k != '_decks');
      final totalDecks = _countDecks(subNode);
      final currentPath = [...path, key];
      final pathKey = 'path_${currentPath.join('_')}';
      
      return _buildCategoryCard(
        context,
        key,
        subNode,
        decks,
        totalDecks,
        hasSubcategories,
        currentPath,
        pathKey,
        path.length,
        deckProvider,
      );
    }).toList();
  }

  int _countDecks(Map<String, dynamic> node) {
    int count = (node['_decks'] as List?)?.length ?? 0;
    
    for (final key in node.keys) {
      if (key != '_decks') {
        count += _countDecks(node[key] as Map<String, dynamic>);
      }
    }
    
    return count;
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String name,
    Map<String, dynamic> node,
    List<Deck> directDecks,
    int totalDecks,
    bool hasSubcategories,
    List<String> path,
    String pathKey,
    int level,
    DeckProvider deckProvider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isExpanded = level == 0 
        ? _expandedCategories.contains(pathKey)
        : _expandedSubcategories.contains(pathKey);

    return Padding(
      padding: EdgeInsets.only(left: level * 12.0, bottom: 8),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: isExpanded ? (level == 0 ? 4 : 2) : (level == 0 ? 2 : 1),
        color: level > 0 ? (isExpanded ? null : Colors.grey.shade50) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(level == 0 ? 16 : 12),
          side: level > 0
              ? BorderSide(
                  color: isExpanded ? AppColors.secondary : Colors.grey.shade300,
                  width: 1,
                )
              : BorderSide.none,
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: Key(pathKey),
            tilePadding: EdgeInsets.symmetric(
              horizontal: level == 0 ? 20 : 16,
              vertical: level == 0 ? 8 : 4,
            ),
            childrenPadding: const EdgeInsets.only(bottom: 8),
            initiallyExpanded: isExpanded,
            onExpansionChanged: (expanded) => _handleExpansionChanged(expanded, level, pathKey),
            leading: _buildCategoryLeading(name, level),
            title: Text(
              translateCategory(name, context), 
              style: TextStyle(
                fontSize: level == 0 ? 18 : 16,
                fontWeight: level == 0 ? FontWeight.bold : FontWeight.w600,
                color: level == 0 ? null : Colors.grey.shade800,
              ),
            ),
            subtitle: Text(
              '$totalDecks ${totalDecks > 1 ? l10n.decks : l10n.deck}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: level == 0 ? 14 : 13,
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: level == 0 ? AppColors.primary : AppColors.secondary,
              size: level == 0 ? 24 : 20,
            ),
            children: [
              if (hasSubcategories)
                ..._buildHierarchyWidgets(context, node, path, deckProvider),
              
              ...directDecks.map((deck) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _buildDeckCard(context, deck, deckProvider, isBase: true),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _handleExpansionChanged(bool expanded, int level, String pathKey) {
    setState(() {
      final targetSet = level == 0 ? _expandedCategories : _expandedSubcategories;
      expanded ? targetSet.add(pathKey) : targetSet.remove(pathKey);
    });
  }

  Widget _buildCategoryLeading(String name, int level) {
    if (level == 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          _getCategoryIcon(name),
          color: AppColors.primary,
          size: 28,
        ),
      );
    }
    
    return Container(
      width: 4,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

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
              icon: const Icon(Icons.add_circle),
              color: AppColors.primary,
              iconSize: 32,
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: deckProvider.customDecks
                    .map((deck) => _buildDeckCard(context, deck, deckProvider, isBase: false))
                    .toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDeckCard(
    BuildContext context,
    Deck deck,
    DeckProvider deckProvider, {
    required bool isBase,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final isSelected = deckProvider.selectedDeck?.id == deck.id;
    final metadata = isBase ? deckProvider.repository.getDeckMetadata(deck.id) : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _selectDeck(context, deck, deckProvider),
        onLongPress: () => _showDeckPreview(context, deck),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildDeckIcon(deck, isSelected),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDeckInfo(deck, metadata, isSelected, l10n, context),
              ),
              _buildDeckActions(context, deck, deckProvider, isSelected, isBase, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeckIcon(Deck deck, bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.2)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        deck.inputType == InputType.text ? Icons.keyboard : Icons.draw,
        color: isSelected ? AppColors.primary : Colors.grey.shade600,
        size: 20,
      ),
    );
  }

  Widget _buildDeckInfo(Deck deck, dynamic metadata, bool isSelected, AppLocalizations l10n, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          deck.localizedName(context),
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.style, size: 12, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(
              l10n.totalWords(deck.totalWords),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            if (metadata?.difficulty != null) ...[
              const SizedBox(width: 8),
              _buildDifficultyChip(context, metadata.difficulty),
            ],
          ],
        ),
        if (deck.progress > 0) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: deck.progress / 100,
              minHeight: 4,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                deck.isCompleted ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDeckActions(
    BuildContext context,
    Deck deck,
    DeckProvider deckProvider,
    bool isSelected,
    bool isBase,
    AppLocalizations l10n,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.visibility, size: 20),
          onPressed: () => _showDeckPreview(context, deck),
          tooltip: 'Prévisualiser',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 4),
        if (isSelected)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 16),
          ),
        if (!isBase)
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, size: 20),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 18),
                    const SizedBox(width: 12),
                    Text(l10n.edit),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, color: AppColors.error, size: 18),
                    const SizedBox(width: 12),
                    Text(l10n.delete, style: const TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'edit') {
                _navigateToEditor(context, deck);
              } else if (value == 'delete') {
                _showDeleteDialog(context, deck, deckProvider);
              }
            },
          ),
      ],
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

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildDifficultyChip(BuildContext context, String difficulty) {
    final l10n = AppLocalizations.of(context)!;
    final (color, label) = switch (difficulty) {
      'beginner' => (AppColors.success, l10n.beginner),
      'intermediate' => (AppColors.warning, l10n.intermediate),
      'advanced' => (AppColors.error, l10n.advanced),
      _ => (Colors.grey, difficulty),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyCustomDecks(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            l10n.noCustomDecks,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.createFirstDeck,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(message, style: TextStyle(color: Colors.grey.shade600)),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    return switch (category.toLowerCase()) {
      'japonais' => Icons.translate,
      'chinois' => Icons.draw,
      'coréen' => Icons.language,
      'espagnol' => Icons.public,
      'français' => Icons.flag,
      _ => Icons.book,
    };
  }

  void _selectDeck(BuildContext context, Deck deck, DeckProvider deckProvider) async {
    final l10n = AppLocalizations.of(context)!;
    await deckProvider.selectDeck(deck);

    if (context.mounted) {
      context.read<GameProvider>().setDeck(deck);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.deckSelected(deck.localizedName(context))),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _navigateToEditor(BuildContext context, Deck? deck) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await Navigator.push<Deck>(
      context,
      MaterialPageRoute(
        builder: (context) => DeckEditorScreen(deck: deck),
      ),
    );

    if (result != null && context.mounted) {
      final deckProvider = context.read<DeckProvider>();

      if (deck == null) {
        await deckProvider.addCustomDeck(result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.deckCreated(result.localizedName(context)))
            ),
          );
        }
      } else {
        await deckProvider.updateCustomDeck(result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.deckModified(result.localizedName(context)))
            ),
          );
        }
      }
    }
  }

  void _showDeleteDialog(BuildContext context, Deck deck, DeckProvider deckProvider) {
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
            onPressed: () async {
              await deckProvider.deleteCustomDeck(deck.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.deckDeleted(deck.localizedName(context)))
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

// Widget de prévisualisation
class DeckPreviewSheet extends StatelessWidget {
  final Deck deck;

  const DeckPreviewSheet({super.key, required this.deck});

  @override
  Widget build(BuildContext context) {
    final words = deck.words.toList();
    final l10n = AppLocalizations.of(context)!;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(context, l10n),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: words.length,
                  itemBuilder: (context, index) {
                    return _buildWordCard(context, words[index], index + 1);
                  },
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  deck.localizedName(context),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.style, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                l10n.totalWords(deck.totalWords),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                deck.inputType == InputType.text ? Icons.keyboard : Icons.draw,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                deck.inputType == InputType.text ? l10n.text : l10n.drawing,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWordCard(BuildContext context, Word word, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '$index',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Prompt:',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          word.prompt,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.arrow_forward, size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'Réponse:',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          word.answer,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}