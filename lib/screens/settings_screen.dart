import 'package:flutter/material.dart';
import '../services/app_settings.dart';
import '../services/language_scope.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings_title'))),
      body: ListView(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: AppSettings.naturalSpeechEnabled,
            builder: (context, enabled, _) {
              return SwitchListTile(
                title: Text(context.tr('natural_speech')),
                subtitle: Text(context.tr('natural_speech_sub')),
                value: enabled,
                onChanged: (value) =>
                    AppSettings.naturalSpeechEnabled.value = value,
              );
            },
          ),
          const Divider(),
          ValueListenableBuilder<bool>(
            valueListenable: AppSettings.switchScanningEnabled,
            builder: (context, enabled, _) {
              return SwitchListTile(
                title: Text(context.tr('switch_scanning')),
                subtitle: Text(context.tr('switch_scanning_sub')),
                value: enabled,
                onChanged: (value) =>
                    AppSettings.switchScanningEnabled.value = value,
              );
            },
          ),
          const Divider(),
          ValueListenableBuilder<String>(
            valueListenable: AppSettings.speakerGender,
            builder: (context, gender, _) {
              return ListTile(
                title: Text(context.tr('speaker_gender')),
                subtitle: Text(context.tr('speaker_gender_sub')),
                trailing: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'masculine',
                      label: Text(context.tr('masculine')),
                    ),
                    ButtonSegment(
                      value: 'feminine',
                      label: Text(context.tr('feminine')),
                    ),
                  ],
                  selected: {gender},
                  onSelectionChanged: (value) =>
                      AppSettings.speakerGender.value = value.first,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
