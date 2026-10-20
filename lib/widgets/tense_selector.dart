import 'package:flutter/material.dart';
import '../services/language_scope.dart';
import '../services/tense_converter.dart';

class TenseSelector extends StatelessWidget {
  final SentenceTense value;
  final String source;
  final String languageCode;
  final ValueChanged<SentenceTense> onChanged;
  final bool conversionRequested;
  const TenseSelector({
    super.key,
    required this.value,
    required this.source,
    required this.languageCode,
    required this.onChanged,
    this.conversionRequested = false,
  });

  @override
  Widget build(BuildContext context) {
    final languageSupported = TenseConverter.supportsLanguage(languageCode);
    final supported = TenseConverter.convert(
      source,
      value,
      languageCode,
    ).supported;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(context.tr('tense_label')),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButton<SentenceTense>(
                key: const ValueKey('tense_selector'),
                isExpanded: true,
                value: value,
                onChanged: languageSupported
                    ? (v) {
                        if (v != null) onChanged(v);
                      }
                    : null,
                items: [
                  for (final tense in SentenceTense.values)
                    DropdownMenuItem(
                      value: tense,
                      child: Text(context.tr('tense_${tense.name}')),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (!languageSupported ||
            (!supported &&
                (conversionRequested || value != SentenceTense.present)))
          Text(
            context.tr(
              languageSupported ? 'tense_unsupported' : 'tense_language',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}
