import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/vocabulary_item.dart';
import '../services/pictogram_assets.dart';

class VocabularyGrid extends StatelessWidget {
  final List<VocabularyItem> items;
  final Function(VocabularyItem) onItemTap;
  final String Function(VocabularyItem)? labelBuilder;
  // When set, tiles show this under the main label - used to show the
  // English original beneath a Twi/Ga translation, so a mixed-language
  // household can still read the board no matter who's holding it.
  final String? Function(VocabularyItem)? secondaryLabelBuilder;
  final VocabularyItem? highlightedItem;

  const VocabularyGrid({
    super.key,
    required this.items,
    required this.onItemTap,
    this.labelBuilder,
    this.secondaryLabelBuilder,
    this.highlightedItem,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 2),
      physics: const NeverScrollableScrollPhysics(),
      // Column count follows the screen: 3 tiles across on a phone held
      // upright, more on a tablet. Bigger than a bare minimum grid on
      // purpose - larger, easier-to-read and easier-to-tap tiles, and the
      // fixed set fills the screen instead of leaving space empty below it.
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 130,
        childAspectRatio: 0.95,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final primaryLabel = labelBuilder?.call(item) ?? item.label;
        final secondaryLabel = secondaryLabelBuilder?.call(item);
        return VocabularyTile(
          item: item,
          label: primaryLabel,
          secondaryLabel: secondaryLabel != primaryLabel ? secondaryLabel : null,
          isHighlighted: highlightedItem != null && item.id == highlightedItem!.id,
          onTap: () => onItemTap(item),
        );
      },
    );
  }
}

class VocabularyTile extends StatelessWidget {
  final VocabularyItem item;
  final String label;
  final String? secondaryLabel;
  final bool isHighlighted;
  final VoidCallback onTap;

  const VocabularyTile({
    super.key,
    required this.item,
    required this.label,
    this.secondaryLabel,
    this.isHighlighted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final localAsset = PictogramAssets.localAssetFor(item.label);
    final hasSymbol = item.symbolUrl != null && item.symbolUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isHighlighted ? Colors.amber.shade200 : Colors.blue.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHighlighted ? Colors.amber.shade900 : Colors.blue.shade400,
            width: isHighlighted ? 4 : 2,
          ),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (localAsset != null)
                // Bundled with the app - renders with zero network calls.
                Expanded(
                  child: Image.asset(localAsset, fit: BoxFit.contain),
                )
              else if (hasSymbol)
                Expanded(
                  child: CachedNetworkImage(
                    imageUrl: item.symbolUrl!,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.image_not_supported,
                      size: 24,
                      color: Colors.grey,
                    ),
                    fit: BoxFit.contain,
                  ),
                )
              else
                const Icon(Icons.image, size: 24, color: Colors.grey),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (secondaryLabel != null)
                Text(
                  secondaryLabel!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
