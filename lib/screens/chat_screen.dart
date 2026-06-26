import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:cross_file/cross_file.dart';
import '../models/plantdoc_models.dart';
import '../services/plantdoc_api.dart';
import '../theme/plantdoc_theme.dart';
import '../l10n_strings.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/mode_strip.dart';
import '../widgets/analysis_sheet.dart';
import '../widgets/backend_url_dialog.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scroll = ScrollController();
  final _msgs = <ChatMessage>[];

  bool _isAr = true;
  bool _isOnline = false;
  bool _isLoading = false;
  String _activeMode = 'leaf';
  String? _sessionId;

  static const _langKey = 'pd_language';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    final lang = p.getString(_langKey) ?? 'ar';
    final sid = await PlantDocApi.getSessionId();
    setState(() {
      _isAr = lang == 'ar';
      _sessionId = sid;
    });
    _checkOnline();
    if (_msgs.isEmpty) _addGreeting();
  }

  Future<void> _checkOnline() async {
    final ok = await PlantDocApi.checkHealth();
    if (mounted) setState(() => _isOnline = ok);
  }

  void _addGreeting() {
    final s = Str(_isAr);
    _msgs.add(ChatMessage(role: ChatRole.bot, text: s.greeting, mode: 'leaf'));
    setState(() {});
  }

  Future<void> _toggleLang() async {
    final p = await SharedPreferences.getInstance();
    setState(() => _isAr = !_isAr);
    await p.setString(_langKey, _isAr ? 'ar' : 'en');
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (_) => BackendUrlDialog(
        isAr: _isAr,
        onSaved: () {
          _checkOnline();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isAr ? 'تم حفظ الرابط' : 'URL saved',
                  style: const TextStyle(fontSize: 13)),
              backgroundColor: PD.green,
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _openAnalysisSheet() {
    final baseUrl = PlantDocApi.getBaseUrl();
    baseUrl.then((url) {
      if (url.isEmpty) {
        _showNoServerSnack();
        return;
      }
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AnalysisSheet(
          isAr: _isAr,
          onAnalyze: _doAnalyze,
        ),
      );
    });
  }

  void _showNoServerSnack() {
    final s = Str(_isAr);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.noServerMsg, style: const TextStyle(fontSize: 12)),
        backgroundColor: PD.surface,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: '⚙️',
          textColor: PD.green,
          onPressed: _openSettings,
        ),
      ),
    );
  }

  Future<void> _doAnalyze({
    XFile? imageFile,
    String plantName = '',
    double? temperatureC,
    double? humidity,
    double? soilMoisture,
    String? cropGrowthStage,
    String? season,
  }) async {
    final s = Str(_isAr);

    String hint = '';
    if (imageFile != null) {
      hint = plantName.isNotEmpty
          ? (s.isAr ? '📷 تحليل صورة — $plantName' : '📷 Analyzing image — $plantName')
          : (s.isAr ? '📷 تحليل صورة النبات' : '📷 Analyzing plant image');
    } else {
      hint = s.isAr ? '🌡️ طلب توصية الري' : '🌡️ Requesting irrigation advice';
    }

    _addMsg(ChatMessage(role: ChatRole.user, text: hint, mode: _activeMode));
    _setLoading(true);

    try {
      final res = await PlantDocApi.analyze(
        imageFile: imageFile,
        plantName: plantName,
        temperatureC: temperatureC,
        humidity: humidity,
        soilMoisture: soilMoisture,
        cropGrowthStage: cropGrowthStage,
        season: season,
        sessionId: _sessionId,
      );

      setState(() {
        _sessionId = res.sessionId;
        _activeMode = res.mode;
        _isOnline = true;
      });

      _addMsg(ChatMessage(role: ChatRole.bot, text: res.finalReport, mode: res.mode));
    } catch (e) {
      _handleError(e.toString(), s);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _sendMessage([String? text]) async {
    final msg = (text ?? _msgCtrl.text).trim();
    if (msg.isEmpty) return;

    final s = Str(_isAr);
    final url = await PlantDocApi.getBaseUrl();
    if (url.isEmpty) {
      _showNoServerSnack();
      return;
    }

    _msgCtrl.clear();

    if (_sessionId == null) {
      _addMsg(ChatMessage(role: ChatRole.user, text: msg, mode: _activeMode));
      _addMsg(ChatMessage(
          role: ChatRole.bot,
          text: s.isAr
              ? 'يرجى رفع صورة أولاً لبدء التحليل، ثم يمكنك طرح أسئلة.'
              : 'Please upload an image first to start the analysis, then you can ask questions.',
          mode: _activeMode));
      return;
    }

    _addMsg(ChatMessage(role: ChatRole.user, text: msg, mode: _activeMode));
    _setLoading(true);

    try {
      final res = await PlantDocApi.chat(
        sessionId: _sessionId!,
        message: msg,
      );
      setState(() {
        _activeMode = res.mode;
        _isOnline = true;
      });
      _addMsg(ChatMessage(role: ChatRole.bot, text: res.reply, mode: res.mode));
    } catch (e) {
      _handleError(e.toString(), s);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _sendFullReport() async {
    if (_sessionId == null) return;
    final s = Str(_isAr);
    _addMsg(ChatMessage(
        role: ChatRole.user,
        text: s.isAr ? '📄 التقرير الكامل' : '📄 Full Report',
        mode: _activeMode));
    _setLoading(true);
    try {
      final res = await PlantDocApi.getReport(_sessionId!);
      setState(() => _isOnline = true);
      _addMsg(ChatMessage(role: ChatRole.bot, text: res.report, mode: res.mode));
    } catch (e) {
      _handleError(e.toString(), s);
    } finally {
      _setLoading(false);
    }
  }

  void _handleError(String e, Str s) {
    final msg = e.contains('NO_SERVER') ? s.noServerMsg : s.connectionError;
    _addMsg(ChatMessage(role: ChatRole.bot, text: '❌ $msg', mode: _activeMode));
    setState(() => _isOnline = false);
  }

  void _addMsg(ChatMessage msg) {
    setState(() => _msgs.add(msg));
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _setLoading(bool v) {
    if (mounted) setState(() => _isLoading = v);
  }

  Future<void> _newChat() async {
    final s = Str(_isAr);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: PD.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: PD.border)),
        title: Text(s.clearConfirm,
            style: pdFont(_isAr, size: 15, weight: FontWeight.w700)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.clearNo,
                  style: const TextStyle(color: PD.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: PD.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.clearYes),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (_sessionId != null) await PlantDocApi.clearSession(_sessionId!);
      setState(() {
        _msgs.clear();
        _sessionId = null;
        _activeMode = 'leaf';
      });
      _addGreeting();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Str(_isAr);
    return Directionality(
      textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: PD.bg,
        appBar: _buildAppBar(s),
        body: Column(
          children: [
            _buildStatusBar(s),
            ModeStrip(activeMode: _activeMode, isAr: _isAr),
            const Divider(height: 1, color: PD.border),
            Expanded(child: _buildMessageList(s)),
            if (_isLoading) _buildTypingIndicator(s),
            if (_sessionId != null) _buildQuickReplies(s),
            _buildInputBar(s),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(Str s) {
    return AppBar(
      backgroundColor: PD.bg,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [PD.greenDark, PD.green],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.spa_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PlantDoc AI',
                  style: pdFont(false,
                      size: 15, weight: FontWeight.w800, color: PD.textPrimary)),
              Text(s.appTagline,
                  style: pdFont(_isAr, size: 10, color: PD.textMuted)),
            ],
          ),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: _toggleLang,
          child: Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: PD.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: PD.border),
            ),
            child: Text(
              _isAr ? 'EN' : 'عربي',
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: PD.textSecondary),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_comment_rounded, color: PD.textSecondary, size: 20),
          onPressed: _newChat,
          tooltip: s.newChat,
        ),
        IconButton(
          icon: const Icon(Icons.settings_rounded, color: PD.textSecondary, size: 20),
          onPressed: _openSettings,
          tooltip: s.settingsTitle,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildStatusBar(Str s) {
    return Container(
      height: 26,
      color: _isOnline ? PD.green.withOpacity(0.08) : PD.red.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _isOnline ? PD.green : PD.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _isOnline ? s.online : s.offline,
            style: TextStyle(
                fontSize: 10,
                color: _isOnline ? PD.green : PD.red,
                fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          if (!_isOnline)
            GestureDetector(
              onTap: _openSettings,
              child: Text(
                _isAr ? 'اضبط الرابط ⚙️' : 'Set URL ⚙️',
                style: const TextStyle(
                    fontSize: 10, color: PD.textMuted, decoration: TextDecoration.underline),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageList(Str s) {
    if (_msgs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded,
                size: 40, color: PD.textMuted),
            const SizedBox(height: 12),
            Text(s.appTagline,
                style: pdFont(_isAr, size: 13, color: PD.textMuted)),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      itemCount: _msgs.length,
      itemBuilder: (_, i) => ChatBubble(msg: _msgs[i], isAr: _isAr),
    );
  }

  Widget _buildTypingIndicator(Str s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: PD.green),
          ),
          const SizedBox(width: 10),
          Text(s.analyzing,
              style: pdFont(_isAr, size: 12, color: PD.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildQuickReplies(Str s) {
    final chips = [
      (s.whatDisease, null),
      (s.treatment, null),
      (s.prevention, null),
      (s.irrigationQ, null),
      if (_activeMode == 'insect') (s.whatInsect, null),
      (s.fullReport, 'report'),
    ];

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: chips.map((c) {
          final isReport = c.$2 == 'report';
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () {
                if (isReport) {
                  _sendFullReport();
                } else {
                  _sendMessage(c.$1);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                decoration: BoxDecoration(
                  color: isReport ? PD.green.withOpacity(0.12) : PD.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isReport ? PD.green.withOpacity(0.3) : PD.border),
                ),
                child: Text(
                  c.$1,
                  style: pdFont(_isAr,
                      size: 11,
                      weight: FontWeight.w600,
                      color: isReport ? PD.green : PD.textSecondary),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputBar(Str s) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
      decoration: const BoxDecoration(
        color: PD.bg,
        border: Border(top: BorderSide(color: PD.border)),
      ),
      child: Row(
        children: [
          _camBtn(),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              style: pdFont(_isAr, size: 14),
              textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: s.msgPlaceholder,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: PD.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: PD.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: PD.green, width: 1.5)),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          _sendBtn(s),
        ],
      ),
    );
  }

  Widget _camBtn() {
    return GestureDetector(
      onTap: _openAnalysisSheet,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: PD.green.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: PD.green.withOpacity(0.25)),
        ),
        child: const Icon(Icons.add_photo_alternate_rounded, color: PD.green, size: 22),
      ),
    );
  }

  Widget _sendBtn(Str s) {
    return GestureDetector(
      onTap: _isLoading ? null : () => _sendMessage(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _isLoading ? PD.surface : PD.green,
          shape: BoxShape.circle,
        ),
        child: _isLoading
            ? const Center(
                child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: PD.green)))
            : Icon(
                _isAr ? Icons.send_rounded : Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
      ),
    );
  }
}
