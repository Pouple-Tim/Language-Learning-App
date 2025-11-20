import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/deck.dart';
import '../../data/models/word.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../l10n/app_localizations.dart';

class DeckEditorScreen extends StatefulWidget {
  final Deck? deck; // null si création, non-null si modification

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
      builder: (context) => _WordDialog(
        onSave: (prompt, answer) {
          setState(() {
            _words.add(Word(prompt: prompt, answer: answer));
          });
        },
      ),
    );
  }

  void _editWord(int index) {
    final word = _words[index];
    showDialog(
      context: context,
      builder: (context) => _WordDialog(
        word: word,
        onSave: (prompt, answer) {
          setState(() {
            _words[index] = Word(prompt: prompt, answer: answer);
          });
        },
      ),
    );
  }

  void _deleteWord(int index) {
    setState(() {
      _words.removeAt(index);
    });
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
        actions: [
          IconButton(
            onPressed: _saveDeck,
            icon: const Icon(Icons.check),
            tooltip: l10n.save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nom du deck
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.deckName,
                  hintText: l10n.deckNameHint,
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.enterName;
                  }
                  if (value.trim().length < AppConstants.minDeckNameLength) {
                    return l10n.nameMinLength(AppConstants.minDeckNameLength);
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Type d'input
              Text(
                l10n.inputType,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InputTypeCard(
                      icon: Icons.keyboard,
                      label: l10n.text,
                      isSelected: _selectedInputType == InputType.text,
                      onTap: () {
                        setState(() {
                          _selectedInputType = InputType.text;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InputTypeCard(
                      icon: Icons.draw,
                      label: l10n.drawing,
                      isSelected: _selectedInputType == InputType.draw,
                      onTap: () {
                        setState(() {
                          _selectedInputType = InputType.draw;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Liste des mots
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

              if (_words.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.add_circle_outline,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          l10n.noWords,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _words.length,
                  itemBuilder: (context, index) {
                    final word = _words[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          word.prompt,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(word.answer),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _editWord(index),
                              tooltip: l10n.edit,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: AppColors.error, size: 20),
                              onPressed: () => _deleteWord(index),
                              tooltip: l10n.delete,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 80),
            ],
          ),
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

// Widget pour sélectionner le type d'input
class _InputTypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _InputTypeCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? AppColors.primary : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dialog pour ajouter/modifier un mot
class _WordDialog extends StatefulWidget {
  final Word? word;
  final Function(String prompt, String answer) onSave;

  const _WordDialog({this.word, required this.onSave});

  @override
  State<_WordDialog> createState() => _WordDialogState();
}

class _WordDialogState extends State<_WordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _promptController;
  late final TextEditingController _answerController;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(text: widget.word?.prompt ?? '');
    _answerController = TextEditingController(text: widget.word?.answer ?? '');
  }

  @override
  void dispose() {
    _promptController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.word != null;
    
    return AlertDialog(
      title: Text(isEditing ? '${l10n.edit} ${l10n.words.toLowerCase()}' : '${l10n.addWord} ${l10n.words.toLowerCase()}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _promptController,
              decoration: InputDecoration(
                labelText: l10n.question,
                hintText: 'Ex: あ',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.enterQuestion;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _answerController,
              decoration: InputDecoration(
                labelText: l10n.answer,
                hintText: 'Ex: a',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.enterAnswer;
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(
                _promptController.text.trim(),
                _answerController.text.trim(),
              );
              Navigator.pop(context);
            }
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}