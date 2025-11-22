import 'package:flutter/material.dart';
import 'package:language_learning_app/data/models/word.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';

class WordEditDialog extends StatefulWidget {
  final Word? word;
  final Function(String prompt, String answer) onSave;

  const WordEditDialog({super.key, this.word, required this.onSave});

  @override
  State<WordEditDialog> createState() => _WordEditDialogState();
}

class _WordEditDialogState extends State<WordEditDialog> {
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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(
        _promptController.text.trim(),
        _answerController.text.trim(),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.word != null;

    return AlertDialog(
      title: Text(isEditing 
          ? '${l10n.edit} ${l10n.words.toLowerCase()}' 
          : '${l10n.addWord} ${l10n.words.toLowerCase()}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _promptController,
              textInputAction: TextInputAction.next,
              autofocus: !isEditing,
              decoration: InputDecoration(
                labelText: l10n.question,
                hintText: 'Ex: あ',
              ),
              validator: (value) => 
                  (value == null || value.trim().isEmpty) ? l10n.enterQuestion : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _answerController,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: l10n.answer,
                hintText: 'Ex: a',
              ),
              validator: (value) => 
                  (value == null || value.trim().isEmpty) ? l10n.enterAnswer : null,
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
          onPressed: _submit,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}