import 'package:flutter/material.dart';
import '../../models/practice.dart';

String practiceTime(int milliseconds) {
  final seconds = (milliseconds / 1000).ceil();
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

String practiceDate(DateTime value) {
  final d = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
}

class PracticeResultSummary extends StatelessWidget {
  final PracticeResult result;
  const PracticeResultSummary({super.key, required this.result});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${result.sentencesPerMinute.toStringAsFixed(1)} sentences per minute',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      Text(
        '${result.sentences} matched · ${practiceTime(result.elapsedMs)} practised',
      ),
      Text(
        '${result.attempts} checks · ${result.skipped} skipped · '
        '${result.accuracy == null ? 'No checks yet' : '${(result.accuracy! * 100).round()}% accuracy'}',
      ),
      const SizedBox(height: 8),
      Text(
        result.completed
            ? 'Full ${result.plannedSeconds ~/ 60}-minute session'
            : 'Ended early · planned ${result.plannedSeconds ~/ 60} minutes. Excluded from personal bests.',
      ),
      const SizedBox(height: 8),
      const Text(
        'SPM = matched sentences ÷ elapsed minutes. Accuracy = matches ÷ checks; skips do not count as checks.',
      ),
      if (result.responses.isNotEmpty)
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text('Review responses (${result.responses.length})'),
          children: [
            for (final response in result.responses)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(switch (response.outcome) {
                  PracticeOutcome.correct => Icons.check_circle_outline,
                  PracticeOutcome.incorrect => Icons.refresh,
                  PracticeOutcome.skipped => Icons.skip_next,
                }),
                title: Text(response.target),
                subtitle: Text(
                  '${response.outcome.name} at ${practiceTime(response.elapsedMs)}'
                  '\nYour words: ${response.answer.isEmpty ? '—' : response.answer}',
                ),
              ),
          ],
        ),
    ],
  );
}
