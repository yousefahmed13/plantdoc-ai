import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class _Msg {
  final String role;
  final String text;
  final DateTime time;
  _Msg({required this.role, required this.text}) : time = DateTime.now();
}

class ChatScreen extends StatefulWidget {
  final String lang;
  final String? analysisContext;

  const ChatScreen({Key? key, required this.lang, this.analysisContext})
      : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<_Msg> _msgs = [];
  final List<Map<String, String>> _history = [];
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _sending = false;

  bool get _hasContext =>
      widget.analysisContext != null && widget.analysisContext!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    final isAr = widget.lang == 'ar';
    final greeting = _hasContext
        ? (isAr
            ? 'مرحباً! لديّ نتائج التحليل محمّلة 🌿\n\nاسألني عن التشخيص، العلاج، الري، أو أي سؤال زراعي.'
            : 'Hello! I have your analysis results loaded 🌿\n\nAsk me about the diagnosis, treatment, irrigation, or any agricultural question.')
        : (isAr
            ? 'مرحباً! أنا AgroVision AI 🌿\n\nاسألني أي سؤال زراعي — أمراض، حشرات، ري، أسمدة...'
            : 'Hello! I am AgroVision AI 🌿\n\nAsk me any agricultural question — diseases, insects, irrigation, fertilizers...');

    setState(() => _msgs.add(_Msg(role: 'model', text: greeting)));
  }

  Future<void> _send() async {
    final txt = _ctrl.text.trim();
    if (txt.isEmpty || _sending) return;

    _ctrl.clear();
    setState(() {
      _msgs.add(_Msg(role: 'user', text: txt));
      _sending = true;
    });
    _scrollDown();

    try {
      final res = await ApiService.chat(
        message: txt,
        history: List.from(_history),
        analysisContext: widget.analysisContext,
      );
      final reply = res['reply']?.toString() ?? '...';
      _history.add({'role': 'user', 'message': txt});
      _history.add({'role': 'model', 'message': reply});
      setState(() => _msgs.add(_Msg(role: 'model', text: reply)));
    } catch (e) {
      final isAr = widget.lang == 'ar';
      setState(() => _msgs.add(_Msg(
            role: 'model',
            text: isAr
                ? 'عذراً، فشل الاتصال بالخادم. تأكد من أن التطبيق شغّال.'
                : 'Sorry, failed to connect to the server. Make sure the app is running.',
          )));
    } finally {
      setState(() => _sending = false);
      _scrollDown();
    }
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.lang == 'ar';
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.accent, AppColors.primary]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.eco_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AgroVision AI', style: appFont(false, size: 14, weight: FontWeight.w800)),
              Text(isAr ? 'مستشار زراعي ذكي' : 'AI Agricultural Advisor',
                  style: appFont(isAr, size: 9, color: AppColors.primary)),
            ]),
          ]),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(children: [
          if (_hasContext)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              color: AppColors.primary.withOpacity(0.06),
              child: Row(children: [
                const Icon(Icons.layers_rounded, size: 13, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(isAr ? 'نتائج التحليل محمّلة تلقائياً' : 'Analysis results auto-loaded',
                    style: appFont(isAr, size: 11, color: AppColors.textSecondary)),
              ]),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.amber.withOpacity(0.08),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isAr ? 'يمكنك الاستشارة المباشرة أو شخّص صورة أولاً للحصول على تحليل' : 'Ask directly or diagnose an image first for full analysis',
                    style: appFont(isAr, size: 11, color: AppColors.amber),
                  ),
                ),
              ]),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _msgs.length + (_sending ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _msgs.length && _sending) return _buildTyping(isAr);
                return _buildBubble(_msgs[i], isAr);
              },
            ),
          ),
          _buildInputBar(isAr),
        ]),
      ),
    );
  }

  Widget _buildBubble(_Msg msg, bool isAr) {
    final isUser = msg.role == 'user';
    final timeStr =
        '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: msg.text));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isAr ? 'تم النسخ' : 'Copied', style: appFont(isAr, size: 12)),
            duration: const Duration(seconds: 1),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.83),
          decoration: BoxDecoration(
            color: isUser ? const Color(0xFF0D2118) : AppColors.card,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
              bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
              bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
            ),
            border: Border.all(
                color: isUser ? AppColors.primary.withOpacity(0.2) : AppColors.cardBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(isUser ? Icons.person_rounded : Icons.eco_rounded,
                      size: 11, color: isUser ? AppColors.primary : AppColors.accent),
                  const SizedBox(width: 5),
                  Text(isUser ? (isAr ? 'أنت' : 'You') : 'AgroVision AI',
                      style: appFont(isAr, size: 9, weight: FontWeight.w800,
                          color: isUser ? AppColors.primary : AppColors.accent)),
                ]),
                const SizedBox(height: 6),
                Text(msg.text,
                    style: appFont(isAr, size: 13, color: AppColors.textPrimary, height: 1.6)),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(timeStr,
                      style: appFont(isAr, size: 9, color: AppColors.textMuted)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTyping(bool isAr) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.accent),
          ),
          const SizedBox(width: 10),
          Text(isAr ? 'AgroVision يفكر...' : 'AgroVision is thinking...',
              style: appFont(isAr, size: 11, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }

  Widget _buildInputBar(bool isAr) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 10, 12, MediaQuery.of(context).viewInsets.bottom + 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            style: appFont(isAr, size: 14),
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            maxLines: 4, minLines: 1,
            decoration: InputDecoration(
              hintText: isAr
                  ? 'اسأل عن الأمراض، الحشرات، الري...'
                  : 'Ask about diseases, insects, irrigation...',
              filled: true, fillColor: AppColors.card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.cardBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.cardBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _send,
          child: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                  color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}
