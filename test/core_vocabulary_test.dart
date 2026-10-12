import 'package:flutter_test/flutter_test.dart';

import 'package:echo_aac/data/core_vocabulary.dart';

void main() {
  test('core vocabulary includes essential communication words', () {
    final labels = CoreVocabulary.getItems().map((item) => item.label).toSet();

    expect(labels, containsAll(['I', 'Help', 'Thank You', 'Yes', 'No']));
  });
}
