import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:echo_aac/models/context.dart';
import 'package:echo_aac/models/echo_language.dart';
import 'package:echo_aac/models/vocabulary_item.dart';
import 'package:echo_aac/services/app_settings.dart';
import 'package:echo_aac/services/user_data_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('People, favorites, usage, contexts and language survive a restart',
      () async {
    SharedPreferences.setMockInitialValues({});
    await UserDataStore.init();

    await UserDataStore.savePeople([
      VocabularyItem(
        id: 'person_1',
        label: 'Brandon',
        collectionId: 'collection_people',
        relationship: 'Brother',
      ),
    ]);
    await UserDataStore.saveFavorites([VocabularyItem(id: 's1', label: 'Tea')]);
    await UserDataStore.saveUsage({'core_1': 4});
    await UserDataStore.saveCustomContexts([
      Context(
        id: 'custom_1',
        label: "Grandma's house",
        vocabulary: [VocabularyItem(id: 'custom_1_0', label: 'Garden')],
      ),
    ]);
    AppSettings.language.value = EchoLanguage.french;
    await UserDataStore.markOnboarded();

    // A fresh start reads it all back from the saved values.
    await UserDataStore.init();

    final people = UserDataStore.loadPeople();
    expect(people.single.label, 'Brandon');
    expect(people.single.relationship, 'Brother');
    expect(UserDataStore.loadFavorites().single.label, 'Tea');
    expect(UserDataStore.loadUsage()['core_1'], 4);
    final contexts = UserDataStore.loadCustomContexts();
    expect(contexts.single.label, "Grandma's house");
    expect(contexts.single.vocabulary.single.label, 'Garden');
    expect(AppSettings.language.value.code, 'fr');
    expect(UserDataStore.onboarded, isTrue);
  });
}
