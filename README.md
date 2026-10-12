# Echo AAC

Echo is an offline-first augmentative and alternative communication (AAC) app
built with Flutter. People build a message from pictogram tiles, choose their
language, and have it spoken aloud. It is designed for any language: it
launches with English, Twi, Ga, Ewe, Dagbani and French. Ewe, Dagbani and French are drafts.

## What it does

- **Board.** A fixed core vocabulary that never moves, plus contexts (Home,
  Hospital, School, Restaurant, Church, Market, Travel) and collections
  (Feel, Food, Places, People).
- **Word library.** More than 1,000 words in 19 category folders with search,
  every one with a bundled ARASAAC pictogram, so the whole library works
  offline. Real photos cover Ghanaian dishes and trotro.
- **Languages.** English, Twi, Ga, Ewe, Dagbani and French. Board words, menus and
  buttons all switch together, tiles show the English original beneath, and
  each word keeps the language it was tapped in, so a sentence can mix
  languages.
- **Speech.** Khaya AI voices for English, Twi, Ga, Ewe and Dagbani (cached after first
  use), and the phone's own voice for French and as an English fallback.
- **Natural Speech.** Suggests a fuller phrasing ("I need my medicine", "Me
  siento cansada", "Je veux de l'eau"). The person always chooses.
- **Emergency phrases** in one tap, spoken at once.
- **Saved on the device.** People, Favorites, most-used words, your own
  contexts and settings survive closing the app. Nothing is sent anywhere.
- **Accessibility.** Switch scanning, grammar options for masculine or
  feminine adjectives, layouts that fit a phone held upright.

French, Twi, Ga, Ewe and Dagbani word lists are drafts and need review by native
speakers.

## Run it

```bash
flutter pub get
flutter run
```

Khaya AI needs a key in `lib/config/khaya_config.dart` (git-ignored):

```dart
class KhayaConfig {
  static const String apiKey = 'your-key';
}
```

## Check it

```bash
flutter analyze
flutter test
```

The tests drive the real app at phone size, offline.

## Rebuilding the word library

Words live in `tools/vocab/words_*.txt` (English and French per line).
Words whose pictogram was checked and found wrong are listed in
`tools/vocab/drop.txt`.

```bash
python tools/build_vocab.py resolve    # match words to ARASAAC pictograms
python tools/build_vocab.py download   # save the images into assets/library/
python tools/build_vocab.py generate   # write the Dart files
```

Always look at the pictograms after adding words: matching by keyword is
usually right but sometimes finds the wrong sense of a word.

To fill in Twi, Ga, Ewe and Dagbani words when the Khaya quota allows
(add `set BOARD_ONLY=1` to skip the word library):

```bash
set KHAYA_API_KEY=your-key
python tools/fetch_khaya_translations.py
```

## Credits and licences

- Pictograms: ARASAAC (Government of Aragon), author Sergio Palao,
  CC BY-NC-SA. Non-commercial use only - check the licence before selling.
- Photos of Ghanaian dishes and trotro: Wikimedia Commons, CC BY-SA / CC BY
  (credits in the app's About screen).
- Translation and speech for Ghanaian languages: GhanaNLP Khaya AI.
