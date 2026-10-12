import 'package:flutter/widgets.dart';
import '../data/ui_strings.dart';
import '../models/echo_language.dart';

/// Makes every screen redraw in the new language the moment it changes,
/// without rebuilding the whole app or losing what has been typed.
class LanguageScope extends InheritedNotifier<ValueNotifier<EchoLanguage>> {
  const LanguageScope({
    super.key,
    required ValueNotifier<EchoLanguage> language,
    required super.child,
  }) : super(notifier: language);

  static EchoLanguage of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LanguageScope>();
    return scope?.notifier?.value ?? EchoLanguage.english;
  }
}

extension TranslateContext on BuildContext {
  /// The text for [key] in the current language. Use {w} or {lang} in the
  /// string and pass [args] to fill them in.
  String tr(String key, [Map<String, String> args = const {}]) {
    var text = UiStrings.get(LanguageScope.of(this).code, key);
    args.forEach((name, value) => text = text.replaceAll('{$name}', value));
    return text;
  }
}
