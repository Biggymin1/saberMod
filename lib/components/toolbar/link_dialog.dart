import 'package:flutter/material.dart';
import 'package:saber/i18n/strings.g.dart';

class LinkDialog extends StatefulWidget {
  const LinkDialog({super.key});

  @override
  State<LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<LinkDialog> {
  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(t.editor.toolbar.link),
      content: TextField(
        controller: _textController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: t.editor.pages),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.common.cancel),
        ),
        TextButton(
          onPressed: () {
            final pageNumber = int.tryParse(_textController.text);
            Navigator.pop(context, pageNumber);
          },
          child: Text(t.common.done),
        ),
      ],
    );
  }
}
