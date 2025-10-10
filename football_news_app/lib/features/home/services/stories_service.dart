// lib/features/home/services/stories_service.dart
import 'dart:convert';
import 'dart:io' as io;

class StoriesService {
  Future<List<Map<String, dynamic>>> fetchStories() async {
    try {
      final url = Uri.parse('https://daily-digest.onefootball.com/es.json');
      final client = io.HttpClient();
      final request = await client.getUrl(url);
      final response = await request.close();

      if (response.statusCode == 200) {
        final jsonString = await response.transform(utf8.decoder).join();
        final data = jsonDecode(jsonString);

        final pages = (data['pages'] as List)
            .where((p) => p['page_type'] == 'article' || p['page_type'] == 'video')
            .map((p) => p['data'] as Map<String, dynamic>)
            .toList();

        return pages;
      }
    } catch (e) {
      // log opcional
    }
    return [];
  }
}
