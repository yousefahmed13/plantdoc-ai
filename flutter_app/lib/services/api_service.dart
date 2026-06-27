import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _defaultBaseUrl =
      'https://b9d43d31-7320-4b49-baf4-5c3c4e8a1f54-00-5gjyqnwnqbi6.spock.replit.dev';

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_base_url') ?? _defaultBaseUrl;
  }

  static Future<void> setBaseUrl(String newUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'api_base_url', newUrl.trim().replaceAll(RegExp(r'/$'), ''));
  }

  static Future<Map<String, dynamic>> analyzeImage({
    required File imageFile,
    String modelType = 'blip2',
    String? plantName,
  }) async {
    final baseUrl = await getBaseUrl();

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final ext = imageFile.path.split('.').last.toLowerCase();
    final mimeType =
        (ext == 'png') ? 'image/png' : 'image/jpeg';

    final response = await http
        .post(
          Uri.parse('$baseUrl/api/analyze'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'image': base64Image,
            'mimeType': mimeType,
            'modelType': modelType,
          }),
        )
        .timeout(const Duration(seconds: 90));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final err = jsonDecode(response.body);
    throw Exception(err['error'] ?? 'فشل التحليل');
  }

  static Future<Map<String, dynamic>> chat({
    required String message,
    List<Map<String, String>>? history,
    String? analysisContext,
    Map<String, dynamic>? irrigationContext,
  }) async {
    final baseUrl = await getBaseUrl();

    final body = <String, dynamic>{'message': message};
    if (history != null && history.isNotEmpty) body['history'] = history;
    if (analysisContext != null) body['analysisContext'] = analysisContext;
    if (irrigationContext != null) body['irrigationContext'] = irrigationContext;

    final response = await http
        .post(
          Uri.parse('$baseUrl/api/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 90));

    if (response.statusCode == 200) return jsonDecode(response.body);
    final err = jsonDecode(response.body);
    throw Exception(err['error'] ?? 'فشل الرد');
  }

  static Future<bool> checkHealth() async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await http
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(const Duration(seconds: 8));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static String parseClassName(String className) {
    return className.replaceAll('_', ' ').replaceAll('  ', ' ').trim();
  }

  static List<String> splitClassName(String className) {
    final parts = className.split('___');
    final plant = parts.isNotEmpty ? parts[0].replaceAll('_', ' ').trim() : '';
    final disease = parts.length > 1
        ? parts[1].replaceAll('_', ' ').replaceAll('  ', ' ').trim()
        : 'Unknown';
    return [plant, disease];
  }
}
