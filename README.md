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

## My Boards

Open the communication board's menu and choose **My Boards**. Create a named
board, add sections, then use **Choose pictograms** to select several words.
Selections remain highlighted while you search; **Done** applies them to the
section. Each tile's menu can move it earlier/later, move it to another section,
or remove it. The section menu can rename, reorder or delete a section.

Choose **Save** to keep your changes. Leaving an edited board asks whether to
discard unsaved changes. The board list offers duplicate and delete actions;
its play button opens **Present mode**. Tap pictures to build a message, then
choose Speak. Stop also cancels speech that is still being downloaded. Previous
and Next switch sections without clearing the message. Changing the speaking
language asks to clear any existing message first. Emergency phrases remain
available in Present mode. Switch scanning follows the setting in Settings
(Space/Enter selects the highlighted item).

Boards are stored locally, separately from existing favorites and contexts.
There is no AI service or account requirement. Bundled pictograms work offline;
speech still depends on installed device voices or cached Khaya audio. In a
browser, data belongs to that browser and site address (including the port).
Changing the development server's IP/port, using private browsing, or clearing
site data can make saved boards unavailable. This feature does not add cloud
backup or guarantee that a development server can be reopened offline.

### Returning to the version before My Boards

The pre-feature checkpoint is commit `8225f11`, tagged
`checkpoint/before-my-boards-20261018`. Feature development is on
`codex/my-boards`. With any later edits committed or otherwise saved, create a
separate recovery branch with:

```powershell
git switch -c recovery/before-my-boards checkpoint/before-my-boards-20261018
```

Return to the feature version with:

```powershell
git switch codex/my-boards
```

This changes the source version; it does not erase saved boards or other local
app data. A source ZIP was also saved outside this repository at
`C:\Users\Papa Offei\.codex\visualizations\2026\10\14\01a13c7f-d7d8-7953-9751-150dc107eef8\Echo-AI-before-my-boards-20261018-verified.zip`.
It includes the local Khaya configuration. Unrelated generated outputs were
left in place. The ZIP can be extracted into a separate folder for an
independent copy of the original source.

On Windows installations with spaces in the Flutter SDK path, native test
hooks may fail with `'C:\Users\Papa' is not recognized`. The Windows short path
works for this installation:

```powershell
& 'C:\Users\PAPAOF~1\Downloads\Flutter\flutter\bin\flutter.bat' test
```

## Message tense

The main communication board and My Boards → Present include a Tense selector.
Present is the default. Build a message, then choose Past, Present or Future;
Speak reads the displayed message. For example, `I want water` becomes
`I wanted water` or `I will want water`. Switching tense always uses the source
message, so repeated changes do not stack extra verbs. Pictograms and saved
board layouts are unchanged. Clear and language changes reset to Present.
Typing an edit starts a new source message; choose a tense again to convert it.

Conversion runs locally without AI or a network request. This first version
supports simple English statements beginning with I, you, he, she, it, we or
they, common verbs, states, and simple negatives. Unknown verbs, questions,
multiple clauses, explicit time words, and complex grammar remain unchanged
with a notice. Other languages show an availability notice and leave the
selector disabled. Natural speech suggestions are hidden in Past/Future so
they cannot accidentally replace a converted message with a present phrase.

The version before this feature is commit `4accb86`, tagged
`checkpoint/before-tense-20261020`. With later edits saved, open that version
on a separate branch:

```powershell
git switch -c recovery/before-tense checkpoint/before-tense-20261020
```

## Timed practice and progress

Open **Menu → Practice**, select or add a learner, choose 1, 2 or 5 minutes,
then **Start practice**. Build the displayed sentence by navigating the real
communication board, its contexts, collections and word library. Tap **Check**
to score a match and move on. A wrong check leaves the message available for
correction; **Skip** moves on without scoring. Delete and Clear work normally.

The current prompt set is `english-varied-v2`. It draws objects from the actual
food, clothing and household vocabulary, checking every subject, verb, modifier
and object against available bundled pictograms. Templates include requests,
polite requests, asking for more, eating/drinking, likes, actions, going
home/outside and polite commands. Grammar tags prevent combinations such as
eating medicine or singular nouns needing unavailable article tiles. Prompts
are shuffled without repeats until the set is exhausted. Practice uses English
without changing the app's selected language. Typing messages, sentence
suggestions, tense conversion and custom phrase shortcuts are unavailable in
practice so matching measures pictogram navigation. Normal communication is
unchanged. Emergency speech remains available and does not build an answer.

The timer starts after the board is ready. Time spent in menus, the word
library or a background tab still counts. Every check verifies the deadline;
late submissions cannot score. Timeout closes any open library/menu and shows
the result. Ending or going back asks to finish early and save the result.

- **Sentences per minute (SPM)** = matched sentences / elapsed minutes. Full
  timed sessions use the selected duration; early-ended sessions use actual
  elapsed time and are excluded from personal bests.
- **Accuracy** = matching checks / all nonempty checks. Skips are recorded
  separately. Empty checks do not count as attempts.
- Each learner has separate local history, total practice time, matched
  sentences, personal bests, latest scores and change against the previous
  full session of the same duration and prompt version. Response details
  retain target, submitted words, outcome and elapsed time for review.

Learners and history live under the separate SharedPreferences key
`practice_v1`. Save retries reuse the session ID, preventing duplicate results;
unreadable or future-version data is never silently overwritten. If saving
fails, the result remains open with Retry. Clear history affects only the
selected learner and preserves other app data. Profiles are local learner
labels, not online accounts. Data is not synced or backed up to a server;
browser/site data deletion removes it. Finish or end a session to save it;
closing the app mid-session can lose that active session.

The version before Practice is commit `081815f`, tagged
`checkpoint/before-practice-20261020`. With later changes saved, recover it on
a separate branch:

```powershell
git switch -c recovery/before-practice checkpoint/before-practice-20261020
```

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
