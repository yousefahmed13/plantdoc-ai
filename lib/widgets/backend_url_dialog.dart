import 'package:flutter/material.dart';
import '../services/plantdoc_api.dart';
import '../theme/plantdoc_theme.dart';
import '../l10n_strings.dart';

class BackendUrlDialog extends StatefulWidget {
  final bool isAr;
  final VoidCallback onSaved;

  const BackendUrlDialog({Key? key, required this.isAr, required this.onSaved}) : super(key: key);

  @override
  State<BackendUrlDialog> createState() => _BackendUrlDialogState();
}

class _BackendUrlDialogState extends State<BackendUrlDialog> {
  final _ctrl = TextEditingController();
  bool _testing = false;
  String? _testResult;
  bool? _testOk;

  @override
  void initState() {
    super.initState();
    PlantDocApi.getBaseUrl().then((url) => _ctrl.text = url);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    final url = _ctrl.text.trim();
    if (url.isEmpty) return;
    await PlantDocApi.setBaseUrl(url);
    setState(() { _testing = true; _testResult = null; });
    final ok = await PlantDocApi.checkHealth();
    final s = Str(widget.isAr);
    setState(() {
      _testing = false;
      _testOk = ok;
      _testResult = ok ? s.settingsConnected : s.settingsDisconnected;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = Str(widget.isAr);
    return Directionality(
      textDirection: widget.isAr ? TextDirection.rtl : TextDirection.ltr,
      child: AlertDialog(
        backgroundColor: PD.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: PD.border),
        ),
        title: Row(
          children: [
            const Icon(Icons.dns_rounded, color: PD.green, size: 20),
            const SizedBox(width: 10),
            Text(s.settingsTitle,
                style: pdFont(widget.isAr, size: 16, weight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.settingsDesc,
                  style: pdFont(widget.isAr, size: 12, color: PD.textSecondary, height: 1.5)),
              const SizedBox(height: 14),
              TextField(
                controller: _ctrl,
                style: pdFont(false, size: 13),
                decoration: InputDecoration(
                  hintText: s.settingsPlaceholder,
                  prefixIcon: const Icon(Icons.link_rounded, size: 18, color: PD.textMuted),
                ),
                onChanged: (_) => setState(() { _testResult = null; _testOk = null; }),
              ),
              if (_testResult != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (_testOk == true ? PD.green : PD.red).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (_testOk == true ? PD.green : PD.red).withOpacity(0.25),
                    ),
                  ),
                  child: Text(
                    _testResult!,
                    style: pdFont(widget.isAr, size: 12,
                        color: _testOk == true ? PD.green : PD.red),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _HowToCard(isAr: widget.isAr),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.settingsCancel,
                style: const TextStyle(color: PD.textSecondary)),
          ),
          if (_testing)
            const SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: PD.green),
            )
          else
            TextButton(
              onPressed: _test,
              child: Text(s.settingsTest,
                  style: const TextStyle(color: PD.teal, fontWeight: FontWeight.w700)),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PD.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final url = _ctrl.text.trim();
              if (url.isNotEmpty) {
                await PlantDocApi.setBaseUrl(url);
                if (context.mounted) Navigator.pop(context);
                widget.onSaved();
              }
            },
            child: Text(s.settingsSave),
          ),
        ],
      ),
    );
  }
}

class _HowToCard extends StatelessWidget {
  final bool isAr;
  const _HowToCard({required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PD.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PD.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? '📋 كيف تحصل على الرابط:' : '📋 How to get the URL:',
            style: pdFont(isAr, size: 11, weight: FontWeight.w700, color: PD.green),
          ),
          const SizedBox(height: 6),
          _step('1', isAr ? 'افتح Kaggle notebook وشغّل كل الخلايا' : 'Open Kaggle notebook and run all cells', isAr),
          _step('2', isAr ? 'في خلية Section 13C انسخ رابط ngrok' : 'In Section 13C cell, copy the ngrok URL', isAr),
          _step('3', isAr ? 'الصق الرابط هنا واضغط حفظ' : 'Paste the URL here and tap Save', isAr),
        ],
      ),
    );
  }

  Widget _step(String n, String text, bool isAr) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              color: PD.green.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(n,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: PD.green)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: pdFont(isAr, size: 11, color: PD.textSecondary, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
