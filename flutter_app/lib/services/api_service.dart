import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String defaultBaseUrl = '';

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_base_url') ?? defaultBaseUrl;
  }

  static Future<void> setBaseUrl(String newUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', newUrl.trimRight().replaceAll(RegExp(r'/$'), ''));
  }

  static Future<String?> getSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('session_id');
  }

  static Future<void> setSessionId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_id', id);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('session_id');
    if (sessionId != null) {
      final baseUrl = await getBaseUrl();
      if (baseUrl.isNotEmpty) {
        try {
          await http
              .delete(Uri.parse('$baseUrl/api/session/$sessionId'))
              .timeout(const Duration(seconds: 5));
        } catch (_) {}
      }
      await prefs.remove('session_id');
    }
  }

  static Future<Map<String, dynamic>> analyzeImage({
    required File imageFile,
    String plantName = '',
    double? temperatureC,
    double? humidity,
    double? soilMoisture,
    String? cropGrowthStage,
    String? season,
    String? sessionId,
  }) async {
    final baseUrl = await getBaseUrl();
    if (baseUrl.isEmpty) {
      throw Exception('الرجاء ضبط رابط الخادم أولاً\nPlease set the server URL first');
    }

    final uri = Uri.parse('$baseUrl/api/analyze');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    if (plantName.isNotEmpty) request.fields['plant_name'] = plantName;
    if (temperatureC != null) request.fields['temperature_c'] = temperatureC.toString();
    if (humidity != null) request.fields['humidity'] = humidity.toString();
    if (soilMoisture != null) request.fields['soil_moisture'] = soilMoisture.toString();
    if (cropGrowthStage != null) request.fields['crop_growth_stage'] = cropGrowthStage;
    if (season != null) request.fields['season'] = season;
    if (sessionId != null) request.fields['session_id'] = sessionId;

    final streamed = await request.send().timeout(const Duration(seconds: 120));
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200 || streamed.statusCode == 201) {
      final data = jsonDecode(body) as Map<String, dynamic>;
      if (data['session_id'] != null) await setSessionId(data['session_id']);
      return data;
    }

    final err = jsonDecode(body);
    throw Exception(err['detail'] ?? err['error'] ?? 'تعذّر التحليل');
  }

  static Future<Map<String, dynamic>> analyzeWeatherOnly({
    required double temperatureC,
    required double humidity,
    required double soilMoisture,
    required String cropGrowthStage,
    required String season,
    String? sessionId,
  }) async {
    final baseUrl = await getBaseUrl();
    if (baseUrl.isEmpty) {
      throw Exception('الرجاء ضبط رابط الخادم أولاً\nPlease set the server URL first');
    }

    final uri = Uri.parse('$baseUrl/api/analyze');
    final request = http.MultipartRequest('POST', uri);

    request.fields['temperature_c'] = temperatureC.toString();
    request.fields['humidity'] = humidity.toString();
    request.fields['soil_moisture'] = soilMoisture.toString();
    request.fields['crop_growth_stage'] = cropGrowthStage;
    request.fields['season'] = season;
    if (sessionId != null) request.fields['session_id'] = sessionId;

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200 || streamed.statusCode == 201) {
      final data = jsonDecode(body) as Map<String, dynamic>;
      if (data['session_id'] != null) await setSessionId(data['session_id']);
      return data;
    }
    final err = jsonDecode(body);
    throw Exception(err['detail'] ?? err['error'] ?? 'تعذّر الحساب');
  }

  static Future<Map<String, dynamic>> chat({
    required String sessionId,
    required String message,
  }) async {
    final baseUrl = await getBaseUrl();
    if (baseUrl.isEmpty) {
      throw Exception('الرجاء ضبط رابط الخادم أولاً\nPlease set the server URL first');
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/api/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'session_id': sessionId, 'message': message}),
        )
        .timeout(const Duration(seconds: 90));

    if (response.statusCode == 200) return jsonDecode(response.body);
    final err = jsonDecode(response.body);
    throw Exception(err['detail'] ?? err['error'] ?? 'تعذّر الرد');
  }

  static Future<Map<String, dynamic>> getFullReport(String sessionId) async {
    final baseUrl = await getBaseUrl();
    if (baseUrl.isEmpty) throw Exception('لا يوجد خادم');

    final response = await http
        .get(Uri.parse('$baseUrl/api/report/$sessionId'))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('لا يوجد تقرير بعد');
  }

  static Future<bool> checkHealth() async {
    try {
      final baseUrl = await getBaseUrl();
      if (baseUrl.isEmpty) return false;
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 8));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
