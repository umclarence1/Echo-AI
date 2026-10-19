import 'package:flutter/material.dart';
import '../../services/language_scope.dart';

Future<String?> boardNameDialog(
  BuildContext context,
  String title, {
  String initial = '',
}) => showDialog<String>(
  context: context,
  builder: (_) => _BoardNameDialog(title: title, initial: initial),
);

class _BoardNameDialog extends StatefulWidget {
  final String title;
  final String initial;
  const _BoardNameDialog({required this.title, required this.initial});
  @override
  State<_BoardNameDialog> createState() => _BoardNameDialogState();
}

class _BoardNameDialogState extends State<_BoardNameDialog> {
  late final controller = TextEditingController(text: widget.initial);
  final formKey = GlobalKey<FormState>();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (formKey.currentState!.validate()) {
      Navigator.pop(context, controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Form(
      key: formKey,
      child: TextFormField(
        controller: controller,
        autofocus: true,
        maxLength: 80,
        decoration: InputDecoration(labelText: context.tr('boards_name')),
        validator: (value) => value == null || value.trim().isEmpty
            ? context.tr('boards_name_required')
            : null,
        onFieldSubmitted: (_) => _submit(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.tr('cancel')),
      ),
      FilledButton(onPressed: _submit, child: Text(context.tr('boards_done'))),
    ],
  );
}

Future<bool> boardConfirm(
  BuildContext context,
  String title,
  String message,
  String action,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;
