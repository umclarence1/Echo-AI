import 'package:flutter/material.dart';
import '../models/vocabulary_item.dart';
import '../services/language_scope.dart';
import '../widgets/vocabulary_grid.dart';

class FavoritesScreen extends StatelessWidget {
  final List<VocabularyItem> items;
  final String Function(VocabularyItem) labelBuilder;
  final void Function(VocabularyItem) onItemTap;

  const FavoritesScreen({
    super.key,
    required this.items,
    required this.labelBuilder,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('favorites_title'))),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  context.tr('favorites_empty'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            )
          : VocabularyGrid(
              items: items,
              labelBuilder: labelBuilder,
              onItemTap: (item) {
                Navigator.pop(context);
                onItemTap(item);
              },
            ),
    );
  }
}
