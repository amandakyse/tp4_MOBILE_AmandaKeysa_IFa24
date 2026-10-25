
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'article_model.dart';

class ApiService {
  static const _apiKey = '65207de0b77145eabcf6a5a588cce4a5';

  Future<List<Article>> fetchArticles({
    String category = 'general',
  }) async {
    final url = Uri.https(
      'newsapi.org',
      '/v2/top-headlines',
      {
        'country': 'us',
        'category': category,
        'apiKey': _apiKey,
      },
    );

    try {
      final response = await http.get(url);
      debugPrint('Status HTTP: ${response.statusCode}');
      debugPrint('Respons API: ${response.body}');

      final Map<String, dynamic> json =
          jsonDecode(response.body);

      if (response.statusCode != 200 ||
          json['status'] != 'ok') {
        throw Exception(
          json['message'] ?? 'Gagal mengambil berita',
        );
      }

      final List<dynamic> data = json['articles'] ?? [];

      return data.map((item) => Article.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Kesalahan API: $e');
      rethrow;
    }
  }
}
