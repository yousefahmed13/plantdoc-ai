class AnalyzeResponse {
  final String sessionId;
  final String mode;
  final String plant;
  final String disease;
  final String? growthStage;
  final String? insectName;
  final bool hasInsectReport;
  final String finalReport;
  final String introMessage;

  const AnalyzeResponse({
    required this.sessionId,
    required this.mode,
    required this.plant,
    required this.disease,
    this.growthStage,
    this.insectName,
    required this.hasInsectReport,
    required this.finalReport,
    required this.introMessage,
  });

  factory AnalyzeResponse.fromJson(Map<String, dynamic> j) => AnalyzeResponse(
        sessionId: j['session_id'] ?? '',
        mode: j['mode'] ?? 'leaf',
        plant: j['plant'] ?? '',
        disease: j['disease'] ?? '',
        growthStage: j['growth_stage'] as String?,
        insectName: j['insect_name'] as String?,
        hasInsectReport: j['has_insect_report'] == true,
        finalReport: j['final_report'] ?? '',
        introMessage: j['intro_message'] ?? '',
      );
}

class ChatResponse {
  final String sessionId;
  final String mode;
  final String reply;

  const ChatResponse({
    required this.sessionId,
    required this.mode,
    required this.reply,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> j) => ChatResponse(
        sessionId: j['session_id'] ?? '',
        mode: j['mode'] ?? 'leaf',
        reply: j['reply'] ?? '',
      );
}

class ReportResponse {
  final String sessionId;
  final String mode;
  final String report;

  const ReportResponse({
    required this.sessionId,
    required this.mode,
    required this.report,
  });

  factory ReportResponse.fromJson(Map<String, dynamic> j) => ReportResponse(
        sessionId: j['session_id'] ?? '',
        mode: j['mode'] ?? 'leaf',
        report: j['report'] ?? '',
      );
}

enum ChatRole { user, bot }

class ChatMessage {
  final ChatRole role;
  final String text;
  final String mode;
  final DateTime time;

  ChatMessage({
    required this.role,
    required this.text,
    this.mode = 'leaf',
  }) : time = DateTime.now();
}
