enum SentenceTense { past, present, future }

class TenseResult {
  final String text;
  final bool supported;
  const TenseResult(this.text, this.supported);
}

/// Offline rules for simple English statements. Unknown grammar is left intact.
/// Always convert the original message, never a previous rendered conversion.
class TenseConverter {
  static bool supportsLanguage(String code) => code == 'en';

  // Base, past, third-person singular. Explicit forms avoid guessing spelling.
  static const _verbs = [
    ['want', 'wanted', 'wants'],
    ['need', 'needed', 'needs'],
    ['feel', 'felt', 'feels'],
    ['go', 'went', 'goes'],
    ['eat', 'ate', 'eats'],
    ['drink', 'drank', 'drinks'],
    ['have', 'had', 'has'],
    ['like', 'liked', 'likes'],
    ['love', 'loved', 'loves'],
    ['help', 'helped', 'helps'],
    ['play', 'played', 'plays'],
    ['work', 'worked', 'works'],
    ['walk', 'walked', 'walks'],
    ['talk', 'talked', 'talks'],
    ['see', 'saw', 'sees'],
    ['hear', 'heard', 'hears'],
    ['say', 'said', 'says'],
    ['come', 'came', 'comes'],
    ['get', 'got', 'gets'],
    ['give', 'gave', 'gives'],
    ['take', 'took', 'takes'],
    ['make', 'made', 'makes'],
    ['do', 'did', 'does'],
    ['know', 'knew', 'knows'],
    ['think', 'thought', 'thinks'],
    ['read', 'read', 'reads'],
    ['write', 'wrote', 'writes'],
    ['sleep', 'slept', 'sleeps'],
    ['sit', 'sat', 'sits'],
    ['stand', 'stood', 'stands'],
    ['buy', 'bought', 'buys'],
    ['bring', 'brought', 'brings'],
    ['learn', 'learned', 'learns'],
    ['study', 'studied', 'studies'],
    ['visit', 'visited', 'visits'],
    ['watch', 'watched', 'watches'],
    ['listen', 'listened', 'listens'],
    ['use', 'used', 'uses'],
    ['live', 'lived', 'lives'],
    ['open', 'opened', 'opens'],
    ['close', 'closed', 'closes'],
    ['stop', 'stopped', 'stops'],
    ['start', 'started', 'starts'],
    ['wait', 'waited', 'waits'],
    ['speak', 'spoke', 'speaks'],
    ['understand', 'understood', 'understands'],
  ];
  static const _states = {
    'happy',
    'sad',
    'angry',
    'scared',
    'excited',
    'tired',
    'sick',
    'confused',
    'hungry',
    'thirsty',
    'ready',
    'hot',
    'cold',
    'okay',
    'fine',
  };

  static TenseResult convert(
    String source,
    SentenceTense tense,
    String language,
  ) {
    TenseResult unchanged() => TenseResult(source, false);
    if (source.trim().isEmpty) return TenseResult(source, true);
    if (!supportsLanguage(language)) return unchanged();
    final match = RegExp(
      r'^(I|you|he|she|it|we|they)\s+(.+?)([.!]?)$',
      caseSensitive: false,
    ).firstMatch(source.trim());
    if (match == null) return unchanged();
    final subject = match[1]!;
    final pronoun = subject.toLowerCase();
    final third = {'he', 'she', 'it'}.contains(pronoun);
    final words = match[2]!.split(RegExp(r'\s+'));
    final lower = words.map((w) => w.toLowerCase()).toList();
    // Multiple clauses, questions, modal/progressive/perfect constructions and
    // explicit time expressions need more context than these rules provide.
    if (RegExp(r'[?;.!]').hasMatch(match[2]!)) return unchanged();
    // Reject clause/time markers even in negative statements.
    if (lower.any(
      {
        'and',
        'but',
        'because',
        'if',
        'when',
        'yesterday',
        'today',
        'tomorrow',
        'already',
      }.contains,
    )) {
      return unchanged();
    }

    var offset = 0;
    var negative = false;
    var auxiliary = false;
    if (lower.first == 'will') {
      auxiliary = true;
      offset++;
      if (offset < lower.length && lower[offset] == 'not') {
        negative = true;
        offset++;
      }
    } else if ({'do', 'does', 'did'}.contains(lower.first) &&
        lower.length > 1 &&
        lower[1] == 'not') {
      negative = true;
      auxiliary = true;
      offset = 2;
    } else if ({"don't", "doesn't", "didn't", "won't"}.contains(lower.first)) {
      negative = true;
      auxiliary = true;
      offset = 1;
    }
    if (offset >= words.length) return unchanged();
    final verb = lower[offset];
    String? outputVerb;
    var restStart = offset + 1;
    final copula = {'am', 'is', 'are', 'was', 'were', 'be'}.contains(verb);
    final state = offset == 0 && _states.contains(verb);
    if (copula || state) {
      if (auxiliary && verb != 'be') return unchanged();
      if (state) restStart = offset;
      if (restStart < lower.length && lower[restStart] == 'not') {
        negative = true;
        restStart++;
      }
      // A bare state adjective or noun complement is supported; participles
      // could be continuous/passive, which this converter does not infer.
      if (lower
          .skip(restStart)
          .any(
            (w) =>
                w.endsWith('ing') ||
                (w.endsWith('ed') && !_states.contains(w)) ||
                {'been', 'being', 'gone', 'eaten'}.contains(w),
          )) {
        return unchanged();
      }
      final be = switch (tense) {
        SentenceTense.past => (pronoun == 'i' || third) ? 'was' : 'were',
        SentenceTense.present =>
          pronoun == 'i'
              ? 'am'
              : third
              ? 'is'
              : 'are',
        SentenceTense.future => 'will be',
      };
      outputVerb = negative
          ? (tense == SentenceTense.future ? 'will not be' : '$be not')
          : be;
    } else {
      for (final forms in _verbs) {
        if (!forms.contains(verb)) continue;
        // Perfect/continuous constructions must not become "hadded" etc.
        if (forms.first == 'have' &&
            lower
                .skip(restStart)
                .take(1)
                .any(
                  (w) =>
                      w.endsWith('ed') ||
                      {'been', 'gone', 'eaten', 'seen', 'done'}.contains(w),
                )) {
          return unchanged();
        }
        if (auxiliary && verb != forms.first) return unchanged();
        outputVerb = negative
            ? switch (tense) {
                SentenceTense.past => 'did not ${forms.first}',
                SentenceTense.present =>
                  '${third ? 'does' : 'do'} not ${forms.first}',
                SentenceTense.future => 'will not ${forms.first}',
              }
            : switch (tense) {
                SentenceTense.past => forms[1],
                SentenceTense.present => third ? forms[2] : forms.first,
                SentenceTense.future => 'will ${forms.first}',
              };
        break;
      }
    }
    if (outputVerb == null || lower.skip(restStart).contains('not')) {
      return unchanged();
    }
    final rest = words.skip(restStart).join(' ');
    final name = pronoun == 'i' ? 'I' : subject;
    return TenseResult(
      '$name $outputVerb${rest.isEmpty ? '' : ' $rest'}${match[3]}',
      true,
    );
  }
}
