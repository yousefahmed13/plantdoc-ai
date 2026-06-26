import 'dart:convert';
import 'package:cross_file/cross_file.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plantdoc_models.dart';

class PlantDocApi {
  static const _urlKey = 'pd_backend_url';
  static const _sessionKey = 'pd_session_id';
  static const _timeout = Duration(seconds: 120);

  static Future<String> getBaseUrl() async {
    final p = await SharedPreferences.getInstance();
    return (p.getString(_urlKey) ?? '').trimRight().replaceAll(RegExp(r'/$'), '');
  }

  static Future<void> setBaseUrl(String url) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_urlKey, url.trimRight().replaceAll(RegExp(r'/$'), ''));
  }

  static Future<String?> getSessionId() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_sessionKey);
  }

  static Future<void> setSessionId(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_sessionKey, id);
  }

  static Future<void> clearSessionId() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_sessionKey);
  }

  static Future<bool> checkHealth() async {
    try {
      final base = await getBaseUrl();
      if (base.isEmpty) return false;
      final res = await http
          .get(Uri.parse('$base/health'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['status'] == 'ok';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> clearSession(String sessionId) async {
    try {
      final base = await getBaseUrl();
      if (base.isEmpty) return;
      await http
          .delete(Uri.parse('$base/api/session/$sessionId'))
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
    await clearSessionId();
  }

  static Future<AnalyzeResponse> analyze({
    XFile? imageFile,
    String plantName = '',
    double? temperatureC,
    double? humidity,
    double? soilMoisture,
    String? cropGrowthStage,
    String? season,
    String? sessionId,
  }) async {
    final base = await getBaseUrl();
    if (base.isEmpty) throw Exception('NO_SERVER');

    final uri = Uri.parse('$base/api/analyze');
    final req = http.MultipartRequest('POST', uri);

    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      req.files.add(http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: imageFile.name.isNotEmpty ? imageFile.name : 'image.jpg',
      ));
    }

    if (plantName.isNotEmpty) req.fields['plant_name'] = plantName;
    if (temperatureC != null) req.fields['temperature_c'] = temperatureC.toString();
    if (humidity != null) req.fields['humidity'] = humidity.toString();
    if (soilMoisture != null) req.fields['soil_moisture'] = soilMoisture.toString();
    if (cropGrowthStage != null) req.fields['crop_growth_stage'] = cropGrowthStage;
    if (season != null) req.fields['season'] = season;
    if (sessionId != null) req.fields['session_id'] = sessionId;

    final streamed = await req.send().timeout(_timeout);
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200 || streamed.statusCode == 201) {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final res = AnalyzeResponse.fromJson(data);
      await setSessionId(res.sessionId);
      return res;
    }

    String msg = 'Analysis failed (${streamed.statusCode})';
    try {
      final e = jsonDecode(body);
      msg = e['detail'] ?? e['error'] ?? msg;
    } catch (_) {}
    throw Exception(msg);
  }

  static Future<ChatResponse> chat({
    required String sessionId,
    required String message,
  }) async {
    final base = await getBaseUrl();
    if (base.isEmpty) throw Exception('NO_SERVER');

    final res = await http
        .post(
          Uri.parse('$base/api/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'session_id': sessionId, 'message': message}),
        )
        .timeout(_timeout);

    if (res.statusCode == 200) return ChatResponse.fromJson(jsonDecode(res.body));

    String msg = 'Chat failed (${res.statusCode})';
    try {
      final e = jsonDecode(res.body);
      msg = e['detail'] ?? e['error'] ?? msg;
    } catch (_) {}
    throw Exception(msg);
  }

  static Future<ReportResponse> getReport(String sessionId) async {
    final base = await getBaseUrl();
    if (base.isEmpty) throw Exception('NO_SERVER');

    final res = await http
        .get(Uri.parse('$base/api/report/$sessionId'))
        .timeout(const Duration(seconds: 30));

    if (res.statusCode == 200) return ReportResponse.fromJson(jsonDecode(res.body));
    throw Exception('No report found');
  }
}
