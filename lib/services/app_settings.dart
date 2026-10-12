import 'package:flutter/foundation.dart';
import '../models/echo_language.dart';

/// App-wide preferences. Values are restored and saved by UserDataStore.
class AppSettings {
  static final ValueNotifier<bool> naturalSpeechEnabled = ValueNotifier(true);

  // Switch scanning: sequentially highlights core vocabulary tiles; a
  // single "switch" signal (spacebar, an external switch mapped to a key
  // press, or the on-screen Select button) activates whichever tile is
  // currently highlighted. First pass covers core vocabulary only.
  static final ValueNotifier<bool> switchScanningEnabled = ValueNotifier(
    false,
  );
  static final ValueNotifier<int> scanIntervalMs = ValueNotifier(1200);

  /// The language of the board, the menus and the voice, all at once.
  static final ValueNotifier<EchoLanguage> language = ValueNotifier(
    EchoLanguage.english,
  );

  /// Used for adjective agreement in French ("cansado" or
  /// "cansada"). Either 'masculine' or 'feminine'.
  static final ValueNotifier<String> speakerGender = ValueNotifier(
    'masculine',
  );

  static bool get speakerIsFeminine => speakerGender.value == 'feminine';
}
