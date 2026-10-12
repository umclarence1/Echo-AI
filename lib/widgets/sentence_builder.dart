import 'package:flutter/material.dart';
import '../services/language_scope.dart';

class SentenceBuilder extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onDelete;
  final VoidCallback onClear;
  final List<String> speechSuggestions;
  final void Function(String suggestion) onApplySuggestion;

  const SentenceBuilder({
    super.key,
    required this.controller,
    required this.onDelete,
    required this.onClear,
    required this.speechSuggestions,
    required this.onApplySuggestion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          if (speechSuggestions.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('nat_title'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  for (final suggestion in speechSuggestions)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              suggestion,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          TextButton(
                            onPressed: () => onApplySuggestion(suggestion),
                            child: Text(context.tr('use')),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                context.tr('nat_empty'),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.backspace_outlined, size: 16),
                label: Text(context.tr('delete')),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.clear_all, size: 16),
                label: Text(context.tr('clear')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
