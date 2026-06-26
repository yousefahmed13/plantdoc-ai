import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/plantdoc_models.dart';
import '../theme/plantdoc_theme.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isAr;

  const ChatBubble({Key? key, required this.msg, required this.isAr}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == ChatRole.user;
    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
        bottom: 10,
      ),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildModeStamp(),
          _buildBubble(context, isUser),
          _buildTime(isUser),
        ],
      ),
    );
  }

  Widget _buildModeStamp() {
    final color = PD.modeColor(msg.mode);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(PD.modeEmoji(msg.mode), style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Text(
              PD.modeLabel(msg.mode, isAr),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(BuildContext context, bool isUser) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: msg.text));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تم نسخ النص' : 'Text copied',
                style: const TextStyle(fontSize: 13)),
            duration: const Duration(seconds: 1),
            backgroundColor: PD.surface,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isUser ? PD.green.withOpacity(0.15) : PD.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
          ),
          border: Border.all(
            color: isUser ? PD.green.withOpacity(0.25) : PD.border,
          ),
        ),
        child: _buildText(msg.text),
      ),
    );
  }

  Widget _buildText(String text) {
    final lines = text.split('\n');
    final spans = <InlineSpan>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (i > 0) spans.add(const TextSpan(text: '\n'));

      if (line.startsWith('• ') || line.startsWith('- ')) {
        spans.add(TextSpan(
          text: '• ${line.substring(2)}',
          style: TextStyle(color: PD.textSecondary, fontSize: 13, height: 1.6),
        ));
      } else if (line.contains('⚠️') || line.contains('WARNING') || line.contains('تحذير')) {
        spans.add(TextSpan(
          text: line,
          style: const TextStyle(color: PD.amber, fontSize: 13, height: 1.6, fontWeight: FontWeight.w600),
        ));
      } else if (line.startsWith('**') && line.endsWith('**') && line.length > 4) {
        spans.add(TextSpan(
          text: line.substring(2, line.length - 2),
          style: const TextStyle(color: PD.textPrimary, fontSize: 14, height: 1.6, fontWeight: FontWeight.w800),
        ));
      } else if (RegExp(r'^\*\*.+\*\*').hasMatch(line)) {
        final parts = _parseBold(line);
        spans.addAll(parts);
      } else if (line.startsWith('━') || line.startsWith('─') || line.startsWith('=')) {
        spans.add(TextSpan(
          text: line,
          style: TextStyle(color: PD.border, fontSize: 11, height: 1.5),
        ));
      } else {
        spans.add(TextSpan(
          text: line,
          style: TextStyle(color: PD.textSecondary, fontSize: 13, height: 1.6),
        ));
      }
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
        children: spans,
      ),
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
    );
  }

  List<InlineSpan> _parseBold(String line) {
    final spans = <InlineSpan>[];
    final re = RegExp(r'\*\*(.+?)\*\*');
    int last = 0;
    for (final m in re.allMatches(line)) {
      if (m.start > last) {
        spans.add(TextSpan(
          text: line.substring(last, m.start),
          style: TextStyle(color: PD.textSecondary, fontSize: 13, height: 1.6),
        ));
      }
      spans.add(TextSpan(
        text: m.group(1),
        style: const TextStyle(color: PD.textPrimary, fontSize: 13, height: 1.6, fontWeight: FontWeight.w700),
      ));
      last = m.end;
    }
    if (last < line.length) {
      spans.add(TextSpan(
        text: line.substring(last),
        style: TextStyle(color: PD.textSecondary, fontSize: 13, height: 1.6),
      ));
    }
    return spans;
  }

  Widget _buildTime(bool isUser) {
    final h = msg.time.hour.toString().padLeft(2, '0');
    final m = msg.time.minute.toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
      child: Text(
        '$h:$m',
        style: const TextStyle(fontSize: 9, color: PD.textMuted),
      ),
    );
  }
}
