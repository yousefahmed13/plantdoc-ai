import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'chat_screen.dart';

class DiagnosisScreen extends StatefulWidget {
  final String lang;
  final String mode;

  const DiagnosisScreen({Key? key, required this.lang, this.mode = 'leaf'}) : super(key: key);

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _analyzing = false;
  Map<String, dynamic>? _result;
  String? _error;
  String? _sessionId;
  final TextEditingController _plantNameCtrl = TextEditingController();

  bool get _isInsect => widget.mode == 'insect';
  bool get _isGrape => widget.mode == 'grape';

  Color get _modeColor {
    if (_isInsect) return AppColors.amber;
    if (_isGrape) return AppColors.grape;
    return AppColors.primary;
  }

  IconData get _modeIcon {
    if (_isInsect) return Icons.bug_report_rounded;
    if (_isGrape) return Icons.spa_rounded;
    return Icons.biotech_rounded;
  }

  String _modeTitle(bool isAr) {
    if (_isInsect) return isAr ? 'تعرّف الحشرات' : 'Insect Identification';
    if (_isGrape) return isAr ? 'مرحلة نمو العنب' : 'Grape Growth Stage';
    return isAr ? 'تشخيص ورقة النبات' : 'Leaf Diagnosis';
  }

  String _modeDescription(bool isAr) {
    if (_isInsect) return isAr
        ? 'يستخدم نموذج ResNet50 المدرّب على 102 نوع من الحشرات الضارة'
        : 'Uses ResNet50 trained on 102 harmful insect species';
    if (_isGrape) return isAr
        ? 'يستخدم ResNet50 لتحديد مرحلة نمو عنقود العنب (3 مراحل: نمو مبكر، متوسط، حصاد)'
        : 'Uses ResNet50 to classify grape bunch growth stage (early / mid+veraison / harvest)';
    return isAr
        ? 'يستخدم BLIP-2 لتشخيص المرض وتحديد النبات من صورة الورقة'
        : 'Uses BLIP-2 to diagnose disease and identify plant from leaf image';
  }

  String _analyzeLabel(bool isAr) {
    if (_isInsect) return isAr ? 'تعرّف على الحشرة' : 'Identify Insect';
    if (_isGrape) return isAr ? 'تحديد مرحلة النمو' : 'Classify Growth Stage';
    return isAr ? 'بدء التشخيص' : 'Analyze Now';
  }

  String _loadingMessage(bool isAr) {
    if (_isInsect) return isAr ? 'جاري تعرّف الحشرة...' : 'Identifying insect...';
    if (_isGrape) return isAr ? 'جاري تحليل مرحلة نمو العنب...' : 'Classifying grape growth stage...';
    return isAr ? 'جاري تحليل الورقة بالذكاء الاصطناعي...' : 'Analyzing leaf with AI...';
  }

  String _imagePrompt(bool isAr) {
    if (_isInsect) return isAr ? 'التقط أو اختر صورة الحشرة' : 'Capture or select insect photo';
    if (_isGrape) return isAr ? 'التقط أو اختر صورة عنقود العنب' : 'Capture or select grape bunch photo';
    return isAr ? 'التقط أو اختر صورة الورقة' : 'Capture or select leaf photo';
  }

  Future<void> _pickImage(ImageSource src) async {
    try {
      final XFile? f = await _picker.pickImage(
        source: src, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
      if (f == null) return;
      setState(() { _imageFile = File(f.path); _result = null; _error = null; });
    } catch (e) {
      setState(() => _error = '${widget.lang == "ar" ? "فشل اختيار الصورة" : "Failed to pick image"}: $e');
    }
  }

  Future<void> _analyze() async {
    if (_imageFile == null) return;
    setState(() { _analyzing = true; _error = null; _result = null; });
    try {
      final existingSession = await ApiService.getSessionId();
      String plantNameHint;
      if (_isInsect) {
        plantNameHint = 'insect';
      } else if (_isGrape) {
        plantNameHint = 'grape';
      } else {
        plantNameHint = _plantNameCtrl.text.trim();
      }
      final data = await ApiService.analyzeImage(
        imageFile: _imageFile!,
        plantName: plantNameHint,
        sessionId: existingSession,
      );
      setState(() { _result = data; _sessionId = data['session_id']; });
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception:', '').trim());
    } finally {
      setState(() => _analyzing = false);
    }
  }

  @override
  void dispose() {
    _plantNameCtrl.dispose();
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
          title: Text(_modeTitle(isAr),
              style: appFont(isAr, size: 16, weight: FontWeight.w700)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(isAr),
              const SizedBox(height: 16),
              if (_isGrape) ...[_buildGrapeStagesCard(isAr), const SizedBox(height: 16)],
              _buildImageZone(isAr),
              if (!_isInsect && !_isGrape) ...[
                const SizedBox(height: 14),
                _buildPlantNameField(isAr),
              ],
              const SizedBox(height: 16),
              if (_error != null) ...[ErrorBox(message: _error!, isAr: isAr), const SizedBox(height: 16)],
              _buildAnalyzeButton(isAr),
              const SizedBox(height: 24),
              if (_analyzing) LoadingOverlay(message: _loadingMessage(isAr), isAr: isAr),
              if (_result != null) _buildResults(isAr),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _modeColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _modeColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(_modeIcon, color: _modeColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_modeDescription(isAr),
                style: appFont(isAr, size: 12, color: AppColors.textSecondary, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildGrapeStagesCard(bool isAr) {
    final stages = isAr
        ? [
            ['🌱', 'المرحلة 1', 'نمو مبكر (إنبات البراعم، نمو البراري، الإزهار)', 'يناير – أبريل'],
            ['🍇', 'المرحلة 2', 'نمو متوسط (تعقد الحبات، النمو، بداية التلوين)', 'مايو – أغسطس'],
            ['🍷', 'المرحلة 3', 'النضج والحصاد', 'أغسطس – أكتوبر'],
          ]
        : [
            ['🌱', 'Stage 1', 'Early growth (bud break, shoot growth & flowering)', 'Jan – Apr'],
            ['🍇', 'Stage 2', 'Mid growth (berry set, development & veraison)', 'May – Aug'],
            ['🍷', 'Stage 3', 'Maturity & Harvest', 'Aug – Oct'],
          ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.grape.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grape.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.timeline_rounded, size: 14, color: AppColors.grape),
            const SizedBox(width: 8),
            Text(isAr ? 'مراحل نمو العنب' : 'Grape Growth Stages',
                style: appFont(isAr, size: 12, weight: FontWeight.w700, color: AppColors.grape)),
          ]),
          const SizedBox(height: 10),
          ...stages.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s[0], style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s[1], style: appFont(isAr, size: 11, weight: FontWeight.w700, color: AppColors.grape)),
                      Text(s[2], style: appFont(isAr, size: 10, color: AppColors.textSecondary, height: 1.4)),
                      Text(s[3], style: appFont(false, size: 9, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildImageZone(bool isAr) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _imageFile != null
                ? Image.file(_imageFile!, height: 220, width: double.infinity, fit: BoxFit.cover)
                : _buildEmptyDropzone(isAr),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildPickBtn(Icons.camera_alt_rounded, isAr ? 'الكاميرا' : 'Camera', AppColors.primary, () => _pickImage(ImageSource.camera))),
              const SizedBox(width: 10),
              Expanded(child: _buildPickBtn(Icons.photo_library_rounded, isAr ? 'المعرض' : 'Gallery', AppColors.blue, () => _pickImage(ImageSource.gallery))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDropzone(bool isAr) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: _modeColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.add_a_photo_rounded, size: 30, color: _modeColor),
          ),
          const SizedBox(height: 14),
          Text(_imagePrompt(isAr),
              style: appFont(isAr, size: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text('JPG · PNG', style: appFont(false, size: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildPickBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label, style: appFont(true, size: 12, weight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantNameField(bool isAr) {
    return TextField(
      controller: _plantNameCtrl,
      style: appFont(isAr, size: 13),
      decoration: InputDecoration(
        hintText: isAr
            ? 'اسم النبات (اختياري) — مثل: طماطم، عنب'
            : 'Plant name (optional) — e.g. tomato, grape',
        prefixIcon: const Icon(Icons.eco_rounded, color: AppColors.textMuted, size: 18),
      ),
    );
  }

  Widget _buildAnalyzeButton(bool isAr) {
    final canAnalyze = _imageFile != null && !_analyzing;
    return GestureDetector(
      onTap: canAnalyze ? _analyze : null,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: canAnalyze
              ? LinearGradient(
                  colors: [_modeColor.withOpacity(0.85), _modeColor],
                  begin: Alignment.centerLeft, end: Alignment.centerRight)
              : null,
          color: canAnalyze ? null : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: canAnalyze ? _modeColor.withOpacity(0.3) : AppColors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_modeIcon, color: canAnalyze ? Colors.white : AppColors.textMuted, size: 20),
            const SizedBox(width: 10),
            Text(_analyzeLabel(isAr),
                style: appFont(isAr, size: 15, weight: FontWeight.w800,
                    color: canAnalyze ? Colors.white : AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(bool isAr) {
    final plant = _result!['plant'] ?? '';
    final disease = _result!['disease'] ?? '';
    final intro = _result!['intro_message'] ?? '';
    final hasInsect = _result!['has_insect_report'] == true;
    final insectName = _result!['insect_name'] ?? '';
    final growthStage = _result!['growth_stage'];
    final sid = _result!['session_id'] ?? _sessionId ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _modeColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _modeColor.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.check_circle_rounded, color: _modeColor, size: 20),
                const SizedBox(width: 8),
                Text(isAr ? 'نتيجة التحليل' : 'Analysis Result',
                    style: appFont(isAr, size: 14, weight: FontWeight.w800, color: _modeColor)),
              ]),
              if (_isGrape && growthStage != null) ...[
                const SizedBox(height: 12),
                _grapeStageResult(growthStage.toString(), isAr),
              ] else ...[
                if (plant.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _resultRow(isAr ? 'النبات' : 'Plant', plant, Icons.eco_rounded, AppColors.primary, isAr),
                ],
                if (disease.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _resultRow(isAr ? 'التشخيص' : 'Diagnosis', disease, Icons.medical_information_rounded, AppColors.amber, isAr),
                ],
                if (insectName.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _resultRow(isAr ? 'الحشرة' : 'Insect', insectName, Icons.bug_report_rounded, AppColors.red, isAr),
                ],
                if (!_isGrape && growthStage != null) ...[
                  const SizedBox(height: 8),
                  _resultRow(isAr ? 'مرحلة النمو' : 'Growth Stage', growthStage.toString(), Icons.timeline_rounded, AppColors.grape, isAr),
                ],
              ],
            ],
          ),
        ),
        if (intro.isNotEmpty) ...[
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(isAr ? 'ملخص الذكاء الاصطناعي' : 'AI Summary',
                      style: appFont(isAr, size: 13, weight: FontWeight.w700, color: AppColors.accent)),
                ]),
                const SizedBox(height: 10),
                Text(intro,
                    style: appFont(isAr, size: 13, color: AppColors.textSecondary, height: 1.6)),
              ],
            ),
          ),
        ],
        if (hasInsect && widget.mode != 'insect') ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.amber.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.amber.withOpacity(0.25)),
            ),
            child: Row(children: [
              const Icon(Icons.bug_report_rounded, color: AppColors.amber, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isAr
                      ? 'تم رصد حشرة في الصورة — اسأل المستشار للتفاصيل'
                      : 'Insect detected in image — ask the advisor for details',
                  style: appFont(isAr, size: 12, color: AppColors.amber),
                ),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => ChatScreen(lang: widget.lang, sessionId: sid))),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [AppColors.accent.withOpacity(0.1), AppColors.primary.withOpacity(0.06)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.accent.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.forum_rounded, color: AppColors.accent, size: 20),
                const SizedBox(width: 10),
                Text(isAr ? 'ناقش النتائج مع المستشار الزراعي' : 'Discuss Results with AI Advisor',
                    style: appFont(isAr, size: 14, weight: FontWeight.w700, color: AppColors.accent)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _grapeStageResult(String stageRaw, bool isAr) {
    final stageMap = {
      '1': isAr
          ? ['المرحلة 1 — نمو مبكر', 'إنبات البراعم، نمو البراري والإزهار', 'يناير – أبريل']
          : ['Stage 1 — Early Growth', 'Bud break, shoot growth & flowering', 'Jan – Apr'],
      '2': isAr
          ? ['المرحلة 2 — نمو متوسط', 'تعقد الحبات، النمو وبداية التلوين (Veraison)', 'مايو – أغسطس']
          : ['Stage 2 — Mid Growth', 'Berry set, development & veraison', 'May – Aug'],
      '3': isAr
          ? ['المرحلة 3 — النضج والحصاد', 'هذه المرحلة النهائية قبل الحصاد، بعدها تدخل الكرمة في السكون', 'أغسطس – أكتوبر']
          : ['Stage 3 — Maturity & Harvest', 'Final stage before harvest; vine enters dormancy after', 'Aug – Oct'],
    };

    final m = RegExp(r'Stage\s*(\d+)', caseSensitive: false).firstMatch(stageRaw);
    final key = m?.group(1) ?? '';
    final info = stageMap[key];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.grape.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grape.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🍇', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(info != null ? info[0] : stageRaw,
                  style: appFont(isAr, size: 15, weight: FontWeight.w800, color: AppColors.grape)),
            ),
          ]),
          if (info != null) ...[
            const SizedBox(height: 8),
            Text(info[1], style: appFont(isAr, size: 12, color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.calendar_month_rounded, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(info[2], style: appFont(false, size: 11, color: AppColors.textMuted)),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value, IconData icon, Color color, bool isAr) {
    return Row(children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 8),
      Text('$label: ', style: appFont(isAr, size: 12, weight: FontWeight.w700, color: color)),
      Expanded(child: Text(value, style: appFont(isAr, size: 12, color: AppColors.textSecondary))),
    ]);
  }
}
