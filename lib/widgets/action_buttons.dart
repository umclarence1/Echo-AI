import 'package:flutter/material.dart';
import '../services/language_scope.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onSpeak;
  final VoidCallback onDelete;
  final VoidCallback onClear;

  const ActionButtons({
    super.key,
    required this.onSpeak,
    required this.onDelete,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    // Three equal buttons that share whatever width the screen has, so the
    // row fits a small phone as well as a tablet.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: context.tr('speak'),
              icon: Icons.volume_up,
              color: Colors.green,
              onPressed: onSpeak,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(
              label: context.tr('delete'),
              icon: Icons.backspace,
              color: Colors.orange,
              onPressed: onDelete,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(
              label: context.tr('clear'),
              icon: Icons.clear,
              color: Colors.red,
              onPressed: onClear,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        minimumSize: const Size(0, 56),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
