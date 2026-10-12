import 'package:flutter/material.dart';
import '../data/image_credits.dart';
import '../services/language_scope.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('about_title'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            context.tr('about_body'),
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('photo_credits'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('photo_credits_sub'),
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          for (final credit in imageCredits)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${credit.label}: ${credit.source}, by ${credit.author} '
                '(${credit.license})',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}
