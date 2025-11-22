import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/data/models/word.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/core/constants/app_constants.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';

// Imports des nouveaux widgets séparés
import 'widgets/word_edit_dialog.dart';
import 'widgets/input_type_selector.dart';
import 'widgets/word_list_tile.dart';

class DeckEditorScreen extends StatefulWidget {
  final Deck? deck;

  const DeckEditorScreen({super.key, this.deck});

  @override
  State<DeckEditorScreen> createState() => _DeckEditorScreenState();
}

class _DeckEditorScreenState extends State<DeckEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  late InputType _selectedInputType;
  final List<Word> _words = [];

  bool get isEditing => widget.deck != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.deck!.name;
      _selectedInputType = widget.deck!.inputType;
      _words.addAll(widget.deck!.words.map((w) => w.copyWith()));
    } else {
      _selectedInputType = InputType.text;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addWord() {
    showDialog(
      context: context,
      builder: (context) => WordEditDialog(
        onSave: (prompt, answer) {
          setState(() => _words.add(Word(prompt: prompt, answer: answer)));
        },
      ),
    );
  }

  void _editWord(int index) {
    showDialog(
      context: context,
      builder: (context) => WordEditDialog(
        word: _words[index],
        onSave: (prompt, answer) {
          setState(() => _words[index] = Word(prompt: prompt, answer: answer));
        },
      ),
    );
  }

  void _deleteWord(int index) {
    final l10n = AppLocalizations.of(context)!;
    final deletedWord = _words[index];
    setState(() => _words.removeAt(index));

    // Optionnel : Permettre d'annuler la suppression
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.wordDeleted),
        action: SnackBarAction(
          label: l10n.cancel,
          onPressed: () {
            setState(() => _words.insert(index, deletedWord));
          },
        ),
      ),
    );
  }

  void _saveDeck() {
    final l10n = AppLocalizations.of(context)!;
    
    if (!_formKey.currentState!.validate()) return;

    if (_words.length < AppConstants.minWordsInDeck) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.addMinWords(AppConstants.minWordsInDeck)),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final deck = Deck(
      id: isEditing ? widget.deck!.id : const Uuid().v4(),
      name: _nameController.text.trim(),
      type: DeckType.custom,
      inputType: _selectedInputType,
      words: _words,
    );

    Navigator.pop(context, deck);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.editDeck : l10n.createNewDeck),
      ),
      body: Form(
        key: _formKey,
        // Utilisation de CustomScrollView pour une meilleure performance de défilement
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.deckName,
                        hintText: l10n.deckNameHint,
                        prefixIcon: const Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return l10n.enterName;
                        if (value.trim().length < AppConstants.minDeckNameLength) {
                          return l10n.nameMinLength(AppConstants.minDeckNameLength);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(l10n.inputType, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    InputTypeSelector(
                      selectedType: _selectedInputType,
                      onTypeChanged: (type) => setState(() => _selectedInputType = type),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${l10n.words} (${_words.length})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        ElevatedButton.icon(
                          onPressed: _addWord,
                          icon: const Icon(Icons.add, size: 20),
                          label: Text(l10n.addWord),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // Liste optimisée
            if (_words.isEmpty)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.add_circle_outline, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(l10n.noWords, style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return WordListTile(
                        index: index,
                        word: _words[index],
                        onEdit: () => _editWord(index),
                        onDelete: () => _deleteWord(index),
                      );
                    },
                    childCount: _words.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveDeck,
        icon: const Icon(Icons.save),
        label: Text(l10n.save),
      ),
    );
  }
}