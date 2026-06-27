import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'diagnosis_screen.dart';
import 'irrigation_screen.dart';
import 'chat_screen.dart';
import 'dictionary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _lang = 'ar';
  bool _isOnline = false;
  bool _checkingHealth = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _checkHealth();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _lang = prefs.getString('pref_lang') ?? 'ar');
  }

  Future<void> _checkHealth() async {
    setState(() => _checkingHealth = true);
    final ok = await ApiService.checkHealth();
    if (mounted) setState(() { _isOnline = ok; _checkingHealth = false; });
  }

  Future<void> _toggleLang() async {
    final prefs = await SharedPreferences.getInstance();
    final newLang = _lang == 'ar' ? 'en' : 'ar';
    await prefs.setString('pref_lang', newLang);
    setState(() => _lang = newLang);
  }

  void _showApiDialog() {
    final ctrl = TextEditingController();
    ApiService.getBaseUrl().then((url) => ctrl.text = url);
    final isAr = _lang == 'ar';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: Text(
          isAr ? 'رابط خادم Kaggle' : 'Kaggle Server URL',
          style: appFont(isAr, size: 16, weight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr
                  ? 'الصق رابط الـ ngrok من الـ Kaggle notebook:'
                  : 'Paste the ngrok URL from your Kaggle notebook:',
              style: appFont(isAr, size: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              style: appFont(false, size: 12),
              decoration: const InputDecoration(
                hintText: 'https://xxxx-xx-xx-xx.ngrok-free.app',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? 'إلغاء' : 'Cancel',
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = ctrl.text.trim();
              if (url.isNotEmpty) {
                await ApiService.setBaseUrl(url);
                if (ctx.mounted) Navigator.pop(ctx);
                _checkHealth();
              }
            },
            child: Text(isAr ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _lang == 'ar';
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: CustomScrollView(
          slivers: [
            _buildAppBar(isAr),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeroBanner(isAr),
                    const SizedBox(height: 28),
                    SectionHeader(title: isAr ? 'أدوات التشخيص' : 'Diagnostic Tools', isAr: isAr),
                    const SizedBox(height: 14),
                    _buildMainGrid(isAr),
                    const SizedBox(height: 28),
                    SectionHeader(title: isAr ? 'المستشار الذكي' : 'AI Consultant', isAr: isAr),
                    const SizedBox(height: 14),
                    _buildChatTile(isAr),
                    const SizedBox(height: 28),
                    SectionHeader(title: isAr ? 'كيف تستخدم التطبيق؟' : 'How to Use', isAr: isAr),
                    const SizedBox(height: 14),
                    _buildHowTo(isAr),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(bool isAr) {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.bg,
      elevation: 0,
      expandedHeight: 72,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.eco_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('AGROVISION AI',
                    style: GoogleFonts.firaCode(
                        fontSize: 8, fontWeight: FontWeight.w800,
                        color: AppColors.primary, letterSpacing: 1.8)),
                Text(isAr ? 'مساعد أمراض النبات' : 'Plant Pathology Assistant',
                    style: appFont(isAr, size: 12, weight: FontWeight.w700, height: 1.2)),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.dns_rounded, color: AppColors.textSecondary, size: 20),
          onPressed: _showApiDialog,
          tooltip: isAr ? 'إعدادات الخادم' : 'Server Settings',
        ),
        GestureDetector(
          onTap: _toggleLang,
          child: Container(
            margin: const EdgeInsets.only(right: 12, left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(isAr ? 'EN' : 'ع',
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBanner(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2118), Color(0xFF0A1929)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.memory_rounded, size: 12, color: AppColors.primary),
                  const SizedBox(width: 5),
                  Text('BLIP-2 · ResNet50 · LLaMA',
                      style: GoogleFonts.firaCode(
                          fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ]),
              ),
              GestureDetector(
                onTap: _checkHealth,
                child: _checkingHealth
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary))
                    : StatusBadge(isOnline: _isOnline, isAr: isAr),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isAr ? 'AgroVision AI\nمنصة تشخيص أمراض النبات' : 'AgroVision AI\nPlant Disease Detection Platform',
            style: appFont(isAr, size: 22, weight: FontWeight.w900, height: 1.3),
          ),
          const SizedBox(height: 8),
          Text(
            isAr
                ? 'موديلات ذكاء اصطناعي متعددة: تشخيص الأمراض، الحشرات، الري، ومستشار زراعي بالعربي والإنجليزي.'
                : 'Multi-model AI: disease detection, insect ID, irrigation, and bilingual agronomic advisor.',
            style: appFont(isAr, size: 12, color: AppColors.textSecondary, height: 1.6),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _chip(Icons.biotech_rounded, 'BLIP-2', AppColors.primary),
              _chip(Icons.bug_report_rounded, isAr ? 'تعرّف الحشرات' : 'Insect ID', AppColors.amber),
              _chip(Icons.water_drop_rounded, isAr ? 'الري الذكي' : 'Smart Irrigation', AppColors.blue),
              _chip(Icons.auto_awesome_rounded, 'LLaMA 4', AppColors.accent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.firaCode(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  Widget _buildMainGrid(bool isAr) {
    final tools = [
      {
        'icon': Icons.camera_enhance_rounded,
        'title': isAr ? 'تشخيص ورقة النبات' : 'Leaf Diagnosis',
        'subtitle': 'BLIP-2 · ResNet50',
        'color': AppColors.primary,
        'bg': const Color(0xFF0D2118),
        'screen': () => DiagnosisScreen(lang: _lang),
      },
      {
        'icon': Icons.water_drop_rounded,
        'title': isAr ? 'حاسبة الري' : 'Smart Irrigation',
        'subtitle': isAr ? 'تحليل الطقس والتربة' : 'Weather & Soil Analysis',
        'color': AppColors.blue,
        'bg': const Color(0xFF0A1929),
        'screen': () => IrrigationScreen(lang: _lang),
      },
      {
        'icon': Icons.bug_report_rounded,
        'title': isAr ? 'تعرّف الحشرات' : 'Insect ID',
        'subtitle': isAr ? '102 نوع حشرة' : '102 Insect Classes',
        'color': AppColors.amber,
        'bg': const Color(0xFF1A1400),
        'screen': () => DiagnosisScreen(lang: _lang, mode: 'insect'),
      },
      {
        'icon': Icons.menu_book_rounded,
        'title': isAr ? 'قاموس الأمراض' : 'Disease Dictionary',
        'subtitle': isAr ? 'قاعدة بيانات محلية' : 'Offline Reference',
        'color': AppColors.accent,
        'bg': const Color(0xFF041A18),
        'screen': () => DictionaryScreen(lang: _lang),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.88,
      ),
      itemCount: tools.length,
      itemBuilder: (context, i) {
        final t = tools[i];
        final color = t['color'] as Color;
        final bg = t['bg'] as Color;
        return GestureDetector(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => (t['screen'] as Function())())),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: Icon(t['icon'] as IconData, color: color, size: 22),
                ),
                const Spacer(),
                Text(t['title'] as String,
                    style: appFont(isAr, size: 13, weight: FontWeight.w800, height: 1.3),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(t['subtitle'] as String,
                    style: appFont(isAr, size: 10, color: AppColors.textSecondary, height: 1.3),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                    child: Icon(
                      isAr ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                      color: color, size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatTile(bool isAr) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => ChatScreen(lang: _lang))),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.accent.withOpacity(0.12), AppColors.primary.withOpacity(0.08)],
            begin: Alignment.centerLeft, end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.accent.withOpacity(0.25)),
        ),
        child: Row(children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.primary],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.forum_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isAr ? 'المستشار الزراعي الذكي' : 'AI Agricultural Advisor',
                  style: appFont(isAr, size: 15, weight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                isAr
                    ? 'اسأل عن الأمراض، الحشرات، الري، والمبيدات'
                    : 'Ask about diseases, insects, irrigation & pesticides',
                style: appFont(isAr, size: 11, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text('LLaMA 4 Scout · Groq',
                    style: GoogleFonts.firaCode(
                        fontSize: 9, color: AppColors.accent, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          Icon(isAr ? Icons.arrow_back_ios_rounded : Icons.arrow_forward_ios_rounded,
              color: AppColors.textMuted, size: 16),
        ]),
      ),
    );
  }

  Widget _buildHowTo(bool isAr) {
    final steps = isAr
        ? [
            ['1', Icons.play_circle_rounded, AppColors.primary, 'شغّل Kaggle notebook', 'افتح النوتبوك وشغّل كل الخلايا حتى تظهر رسالة ngrok URL'],
            ['2', Icons.link_rounded, AppColors.blue, 'انسخ رابط ngrok', 'الرابط بيظهر في آخر خلية - يبدأ بـ https://'],
            ['3', Icons.settings_rounded, AppColors.amber, 'الصق الرابط هنا', 'اضغط أيقونة الخادم ⚙️ في الأعلى والصق الرابط'],
            ['4', Icons.camera_enhance_rounded, AppColors.accent, 'ابدأ التشخيص', 'التقط صورة ورقة نبات وانتظر التحليل بالذكاء الاصطناعي'],
          ]
        : [
            ['1', Icons.play_circle_rounded, AppColors.primary, 'Run Kaggle notebook', 'Open the notebook and run all cells until the ngrok URL appears'],
            ['2', Icons.link_rounded, AppColors.blue, 'Copy the ngrok URL', 'The URL appears in the last cell — starts with https://'],
            ['3', Icons.settings_rounded, AppColors.amber, 'Paste URL in app', 'Tap the ⚙️ server icon above and paste the URL'],
            ['4', Icons.camera_enhance_rounded, AppColors.accent, 'Start diagnosing', 'Capture a leaf photo and wait for the AI analysis'],
          ];

    return Column(
      children: steps.map((s) {
        final color = s[2] as Color;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(s[1] as IconData, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s[3] as String, style: appFont(isAr, size: 13, weight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(s[4] as String,
                    style: appFont(isAr, size: 11, color: AppColors.textSecondary, height: 1.4)),
              ]),
            ),
          ]),
        );
      }).toList(),
    );
  }
}
