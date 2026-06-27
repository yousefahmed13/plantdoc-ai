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

  const DiagnosisScreen({Key? key, required this.lang, this.mode = 'leaf'})
      : super(key: key);

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _analyzing = false;
  Map<String, dynamic>? _result;
  String? _error;
  final TextEditingController _plantNameCtrl = TextEditingController();

  String _selectedModel = 'blip2';

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

  String _loadingMessage(bool isAr) {
    return isAr ? 'جاري تحليل الصورة بالذكاء الاصطناعي...' : 'Analyzing image with AI...';
  }

  String _analyzeLabel(bool isAr) {
    if (_isInsect) return isAr ? 'تعرّف على الحشرة' : 'Identify Insect';
    if (_isGrape) return isAr ? 'تحديد مرحلة النمو' : 'Classify Growth Stage';
    return isAr ? 'بدء التشخيص' : 'Analyze Now';
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
      setState(() {
        _imageFile = File(f.path);
        _result = null;
        _error = null;
      });
    } catch (e) {
      setState(() => _error =
          '${widget.lang == "ar" ? "فشل اختيار الصورة" : "Failed to pick image"}: $e');
    }
  }

  Future<void> _analyze() async {
    if (_imageFile == null) return;
    setState(() {
      _analyzing = true;
      _error = null;
      _result = null;
    });
    try {
      final data = await ApiService.analyzeImage(
        imageFile: _imageFile!,
        modelType: _selectedModel,
        plantName: _plantNameCtrl.text.trim(),
      );
      setState(() => _result = data);
    } catch (e) {
      setState(() =>
          _error = e.toString().replaceAll('Exception:', '').trim());
    } finally {
      setState(() => _analyzing = false);
    }
  }

  String _buildAnalysisContext() {
    if (_result == null) return '';
    final modelType = _result!['modelType'] ?? '';
    final result = _result!['result'];
    if (result == null) return '';

    if (result is Map) {
      final className = result['className']?.toString() ?? '';
      final confidence = result['confidence'];
      final parts = ApiService.splitClassName(className);
      return 'Model: $modelType\nPlant: ${parts[0]}\nDisease/Condition: ${parts[1]}\nConfidence: ${confidence != null ? '${(confidence * 100).toStringAsFixed(1)}%' : 'N/A'}\nFull Class: $className';
    } else if (result is String) {
      return 'Model: $modelType\nAnalysis:\n$result';
    }
    return '';
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
              _buildModelSelector(isAr),
              const SizedBox(height: 16),
              _buildImageZone(isAr),
              if (!_isInsect && !_isGrape) ...[
                const SizedBox(height: 14),
                _buildPlantNameField(isAr),
              ],
              const SizedBox(height: 16),
              if (_error != null) ...[
                ErrorBox(message: _error!, isAr: isAr),
                const SizedBox(height: 16),
              ],
              _buildAnalyzeButton(isAr),
              const SizedBox(height: 24),
              if (_analyzing)
                LoadingOverlay(message: _loadingMessage(isAr), isAr: isAr),
              if (_result != null) _buildResults(isAr),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModelSelector(bool isAr) {
    final models = [
      ['blip2', isAr ? 'BLIP-2 (تشخيص شامل)' : 'BLIP-2 (Full Diagnosis)', AppColors.primary],
      ['resnet50', isAr ? 'ResNet50 (تصنيف سريع)' : 'ResNet50 (Fast)', AppColors.blue],
      ['llava', 'LLaVA (تحليل عميق)', AppColors.accent],
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isAr ? 'اختر الموديل' : 'Select Model',
              style: appFont(isAr, size: 11, color: AppColors.textSecondary, weight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: models.map((m) {
              final selected = _selectedModel == m[0];
              final color = m[2] as Color;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedModel = m[0] as String),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? color.withOpacity(0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: selected ? color : AppColors.cardBorder, width: selected ? 1.5 : 1),
                    ),
                    child: Text(m[1] as String,
                        textAlign: TextAlign.center,
                        style: appFont(isAr, size: 9, weight: FontWeight.w700,
                            color: selected ? color : AppColors.textMuted)),
                  ),
                ),
              );
            }).toList(),
          ),
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
          Row(children: [
            Expanded(child: _buildPickBtn(Icons.camera_alt_rounded,
                isAr ? 'الكاميرا' : 'Camera', AppColors.primary, () => _pickImage(ImageSource.camera))),
            const SizedBox(width: 10),
            Expanded(child: _buildPickBtn(Icons.photo_library_rounded,
                isAr ? 'المعرض' : 'Gallery', AppColors.blue, () => _pickImage(ImageSource.gallery))),
          ]),
        ],
      ),
    );
  }

  Widget _buildEmptyDropzone(bool isAr) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(12),
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
          Text(_imagePrompt(isAr), style: appFont(isAr, size: 13, color: AppColors.textSecondary)),
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
          color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: appFont(true, size: 12, weight: FontWeight.w700, color: color)),
        ]),
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
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(_modeIcon, color: canAnalyze ? Colors.white : AppColors.textMuted, size: 20),
          const SizedBox(width: 10),
          Text(_analyzeLabel(isAr),
              style: appFont(isAr, size: 15, weight: FontWeight.w800,
                  color: canAnalyze ? Colors.white : AppColors.textMuted)),
        ]),
      ),
    );
  }

  Widget _buildResults(bool isAr) {
    final modelType = _result!['modelType'] ?? '';
    final result = _result!['result'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (result is Map) _buildClassificationResult(result, modelType, isAr)
        else if (result is String) _buildTextResult(result, modelType, isAr),
        const SizedBox(height: 12),
        _buildChatButton(isAr),
      ],
    );
  }

  Widget _buildClassificationResult(Map result, String modelType, bool isAr) {
    final className = result['className']?.toString() ?? '';
    final confidence = result['confidence'] as double? ?? 0;
    final parts = ApiService.splitClassName(className);
    final plant = parts[0];
    final disease = parts[1];
    final isHealthy = disease.toLowerCase().contains('healthy');

    return Container(
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
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(modelType.toUpperCase(),
                  style: appFont(false, size: 9, weight: FontWeight.w800, color: AppColors.blue)),
            ),
          ]),
          const SizedBox(height: 14),
          _resultRow(isAr ? 'النبات' : 'Plant', plant, Icons.eco_rounded, AppColors.primary, isAr),
          const SizedBox(height: 8),
          _resultRow(isAr ? 'الحالة' : 'Condition', disease,
              isHealthy ? Icons.check_circle_rounded : Icons.medical_information_rounded,
              isHealthy ? AppColors.primary : AppColors.amber, isAr),
          const SizedBox(height: 12),
          Row(children: [
            Text(isAr ? 'الثقة: ' : 'Confidence: ',
                style: appFont(isAr, size: 11, color: AppColors.textSecondary)),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: confidence,
                  backgroundColor: AppColors.cardBorder,
                  color: isHealthy ? AppColors.primary : AppColors.amber,
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('${(confidence * 100).toStringAsFixed(1)}%',
                style: appFont(false, size: 11, weight: FontWeight.w700,
                    color: isHealthy ? AppColors.primary : AppColors.amber)),
          ]),
        ],
      ),
    );
  }

  Widget _buildTextResult(String text, String modelType, bool isAr) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.accent),
            const SizedBox(width: 8),
            Text(isAr ? 'تحليل الذكاء الاصطناعي' : 'AI Analysis',
                style: appFont(isAr, size: 13, weight: FontWeight.w700, color: AppColors.accent)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(modelType.toUpperCase(),
                  style: appFont(false, size: 9, weight: FontWeight.w800, color: AppColors.accent)),
            ),
          ]),
          const SizedBox(height: 10),
          Text(text, style: appFont(isAr, size: 13, color: AppColors.textSecondary, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildChatButton(bool isAr) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            lang: widget.lang,
            analysisContext: _buildAnalysisContext(),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [AppColors.accent.withOpacity(0.1), AppColors.primary.withOpacity(0.06)]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.accent.withOpacity(0.25)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.forum_rounded, color: AppColors.accent, size: 20),
          const SizedBox(width: 10),
          Text(isAr ? 'ناقش النتائج مع المستشار الزراعي' : 'Discuss Results with AI Advisor',
              style: appFont(isAr, size: 14, weight: FontWeight.w700, color: AppColors.accent)),
        ]),
      ),
    );
  }

  Widget _resultRow(String label, String value, IconData icon, Color color, bool isAr) {
    return Row(children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 8),
      Text('$label: ', style: appFont(isAr, size: 12, weight: FontWeight.w700, color: color)),
      Expanded(
          child: Text(value, style: appFont(isAr, size: 12, color: AppColors.textSecondary))),
    ]);
  }
}
