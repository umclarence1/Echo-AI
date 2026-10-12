import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'services/app_settings.dart';
import 'services/language_scope.dart';
import 'services/user_data_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserDataStore.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LanguageScope(
      language: AppSettings.language,
      child: MaterialApp(
        title: 'Echo AAC',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
