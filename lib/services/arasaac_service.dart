import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ArasaacService {
  static const String baseUrl = 'https://api.arasaac.org/v1';
  static const String imageBaseUrl = 'https://static.arasaac.org/pictograms';

  /// Search for pictograms by keyword
  static Future<List<String>> searchPictograms(
    String keyword, {
    String language = 'en',
  }) async {
    try {
      final encodedKeyword = Uri.encodeComponent(keyword.trim());
      final url = Uri.parse(
        '$baseUrl/pictograms/$language/search/$encodedKeyword',
      );
      debugPrint('Searching ARASAAC: $url');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final ids = data.map((item) => item['_id'].toString()).toList();
        debugPrint('Found pictogram IDs: $ids');
        return ids;
      }
      return [];
    } catch (e) {
      debugPrint('Error searching pictograms: $e');
      return [];
    }
  }

  /// Get pictogram image URL by ID
  static String getPictogramUrl(String pictogramId) {
    return '$imageBaseUrl/$pictogramId/${pictogramId}_500.png';
  }

  /// Get pictogram details
  static Future<Map<String, dynamic>?> getPictogramDetails(
    String pictogramId,
  ) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/pictograms/$pictogramId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting pictogram details: $e');
      return null;
    }
  }
}
