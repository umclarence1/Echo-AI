import 'package:flutter/material.dart';
import '../data/library_vocabulary.dart';
import '../models/vocabulary_item.dart';
import '../services/language_scope.dart';
import '../widgets/vocabulary_grid.dart';

/// Browse every word in the library by category, or search all of them.
/// Tapping a word returns it to the board.
class LibraryScreen extends StatefulWidget {
  final List<VocabularyItem> items;
  final String Function(String english) categoryName;
  final String Function(VocabularyItem) labelBuilder;
  final String? Function(VocabularyItem) secondaryLabelBuilder;
  final void Function(VocabularyItem) onItemTap;

  const LibraryScreen({
    super.key,
    required this.items,
    required this.categoryName,
    required this.labelBuilder,
    required this.secondaryLabelBuilder,
    required this.onItemTap,
  });

  /// All library words as board items, made once.
  static final List<VocabularyItem> allItems = [
    for (final category in LibraryVocabulary.categories)
      for (final word in category.words)
        VocabularyItem(
          id: 'lib_${word.label}',
          label: word.label,
          collectionId: category.id,
        ),
  ];

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _search = TextEditingController();
  String? _categoryId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<VocabularyItem> get _visible {
    final query = _search.text.trim().toLowerCase();
    return widget.items.where((item) {
      if (query.isNotEmpty) {
        final shown = widget.labelBuilder(item).toLowerCase();
        return item.label.toLowerCase().contains(query) ||
            shown.contains(query);
      }
      return _categoryId == null || item.collectionId == _categoryId;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('library')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: context.tr('library_search'),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(context.tr('all_words')),
                    selected: _categoryId == null,
                    onSelected: (_) => setState(() => _categoryId = null),
                  ),
                ),
                for (final category in LibraryVocabulary.categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(widget.categoryName(category.label)),
                      selected: _categoryId == category.id,
                      onSelected: (_) =>
                          setState(() => _categoryId = category.id),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Text(
                      context.tr('library_none'),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 110,
                          childAspectRatio: 0.9,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final item = visible[index];
                      final secondary = widget.secondaryLabelBuilder(item);
                      final label = widget.labelBuilder(item);
                      return VocabularyTile(
                        item: item,
                        label: label,
                        secondaryLabel: secondary != label ? secondary : null,
                        onTap: () {
                          Navigator.pop(context);
                          widget.onItemTap(item);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
