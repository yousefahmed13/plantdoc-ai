import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'chat_screen.dart';

class IrrigationScreen extends StatefulWidget {
  final String lang;
  const IrrigationScreen({Key? key, required this.lang}) : super(key: key);

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen> {
  final _stages = ['Germination', 'Vegetative', 'Flowering', 'Fruiting', 'Harvesting'];
  final _seasons = ['Spring', 'Summer', 'Autumn', 'Winter', 'Rabi', 'Kharif'];
  final _stageAr = {'Germination': 'الإنبات', 'Vegetative': 'الخضري', 'Flowering': 'التزهير', 'Fruiting': 'الإثمار', 'Harvesting': 'الحصاد'};
  final _seasonAr = {'Spring': 'الربيع', 'Summer': 'الصيف', 'Autumn': 'الخريف', 'Winter': 'الشتاء', 'Rabi': 'شتوي', 'Kharif': 'صيفي'};

  String _stage = 'Vegetative';
  String _season = 'Summer';
  double _temp = 28;
  double _humidity = 55;
  double _soil = 45;

  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  Future<void> _calculate() async {
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final existingSession = await ApiService.getSessionId();
      final data = await ApiService.analyzeWeatherOnly(
        temperatureC: _temp,
        humidity: _humidity,
        soilMoisture: _soil,
        cropGrowthStage: _stage,
        season: _season,
        sessionId: existingSession,
      );
      setState(() => _result = data);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception:', '').trim());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.lang == 'ar';
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: Text(isAr ? 'حاسبة الري الذكية' : 'Smart Irrigation',
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
              _infoCard(isAr),
              const SizedBox(height: 20),
              _sectionLabel(isAr ? 'مرحلة النمو والموسم' : 'Growth Stage & Season', isAr),
              const SizedBox(height: 10),
              AppCard(
                child: Row(children: [
                  Expanded(child: _dropdown(isAr ? 'مرحلة النمو' : 'Growth Stage', _stage, _stages, isAr ? _stageAr : null, (v) => setState(() => _stage = v!), isAr)),
                  const SizedBox(width: 12),
                  Expanded(child: _dropdown(isAr ? 'الموسم' : 'Season', _season, _seasons, isAr ? _seasonAr : null, (v) => setState(() => _season = v!), isAr)),
                ]),
              ),
              const SizedBox(height: 20),
              _sectionLabel(isAr ? 'القياسات الميدانية' : 'Field Measurements', isAr),
              const SizedBox(height: 10),
              AppCard(
                child: Column(children: [
                  _slider(isAr ? 'درجة الحرارة' : 'Temperature', _temp, 0, 50, '°C', AppColors.amber, (v) => setState(() => _temp = v), isAr),
                  _slider(isAr ? 'الرطوبة النسبية' : 'Humidity', _humidity, 0, 100, '%', AppColors.blue, (v) => setState(() => _humidity = v), isAr),
                  _slider(isAr ? 'رطوبة التربة' : 'Soil Moisture', _soil, 0, 100, '%', AppColors.primary, (v) => setState(() => _soil = v), isAr),
                ]),
              ),
              const SizedBox(height: 20),
              if (_error != null) ...[ErrorBox(message: _error!, isAr: isAr), const SizedBox(height: 16)],
              _calcButton(isAr),
              const SizedBox(height: 24),
              if (_loading) LoadingOverlay(
                  message: isAr ? 'جاري حساب الاحتياجات المائية...' : 'Calculating water requirements...', isAr: isAr),
              if (_result != null) _buildResult(isAr),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blue.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.blue.withOpacity(0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.water_drop_rounded, color: AppColors.blue, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            isAr
                ? 'أدخل بيانات الطقس والتربة — سيحلّلها الذكاء الاصطناعي ويحسب الاحتياج المائي'
                : 'Enter weather & soil data — AI will analyze and calculate water requirements',
            style: appFont(isAr, size: 12, color: AppColors.textSecondary, height: 1.5),
          ),
        ),
      ]),
    );
  }

  Widget _sectionLabel(String title, bool isAr) {
    return Text(title, style: appFont(isAr, size: 13, weight: FontWeight.w700, color: AppColors.textSecondary));
  }

  Widget _dropdown(String label, String value, List<String> items, Map<String, String>? labels,
      ValueChanged<String?> onChanged, bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: appFont(isAr, size: 11, color: AppColors.textSecondary, weight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          dropdownColor: AppColors.card,
          style: appFont(isAr, size: 12),
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
          items: items.map((e) => DropdownMenuItem(
            value: e,
            child: Text(labels != null ? (labels[e] ?? e) : e, style: appFont(isAr, size: 12)),
          )).toList(),
        ),
      ],
    );
  }

  Widget _slider(String label, double value, double min, double max, String unit, Color color,
      ValueChanged<double> onChanged, bool isAr) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: appFont(isAr, size: 12, color: AppColors.textSecondary)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text('${value.toStringAsFixed(0)}$unit',
              style: appFont(false, size: 11, weight: FontWeight.w700, color: color)),
        ),
      ]),
      SliderTheme(
        data: SliderThemeData(
          activeTrackColor: color, inactiveTrackColor: color.withOpacity(0.15),
          thumbColor: color, overlayColor: color.withOpacity(0.1),
          trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        ),
        child: Slider(value: value, min: min, max: max, onChanged: onChanged),
      ),
      const SizedBox(height: 4),
    ]);
  }

  Widget _calcButton(bool isAr) {
    return GestureDetector(
      onTap: _loading ? null : _calculate,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: _loading ? null : const LinearGradient(
              colors: [AppColors.blue, Color(0xFF2563EB)],
              begin: Alignment.centerLeft, end: Alignment.centerRight),
          color: _loading ? AppColors.card : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.water_drop_rounded, color: _loading ? AppColors.textMuted : Colors.white, size: 20),
          const SizedBox(width: 10),
          Text(isAr ? 'احسب الري الآن' : 'Calculate Irrigation',
              style: appFont(isAr, size: 15, weight: FontWeight.w800,
                  color: _loading ? AppColors.textMuted : Colors.white)),
        ]),
      ),
    );
  }

  Widget _buildResult(bool isAr) {
    final intro = _result!['intro_message'] ?? _result!['final_report'] ?? '';
    final sessionId = _result!['session_id'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF0A1929), Color(0xFF0D1F1A)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.blue.withOpacity(0.3)),
          ),
          child: Column(children: [
            const Icon(Icons.water_drop_rounded, color: AppColors.blue, size: 36),
            const SizedBox(height: 10),
            Text(isAr ? 'تحليل الري' : 'Irrigation Analysis',
                style: appFont(isAr, size: 16, weight: FontWeight.w900, color: AppColors.blue)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Text(isAr ? 'تم الحساب بواسطة AI' : 'Calculated by AI',
                  style: appFont(isAr, size: 12, weight: FontWeight.w700, color: AppColors.primary)),
            ),
          ]),
        ),
        if (intro.isNotEmpty) ...[
          const SizedBox(height: 12),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.analytics_rounded, size: 14, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(isAr ? 'توصيات الري' : 'Irrigation Recommendations',
                    style: appFont(isAr, size: 13, weight: FontWeight.w700, color: AppColors.accent)),
              ]),
              const SizedBox(height: 10),
              Text(intro.toString(),
                  style: appFont(isAr, size: 13, color: AppColors.textSecondary, height: 1.6)),
            ]),
          ),
        ],
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ChatScreen(lang: widget.lang, sessionId: sessionId))),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.accent.withOpacity(0.2)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.forum_rounded, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Text(isAr ? 'ناقش مع المستشار الزراعي' : 'Discuss with AI Advisor',
                  style: appFont(isAr, size: 13, weight: FontWeight.w700, color: AppColors.accent)),
            ]),
          ),
        ),
      ],
    );
  }
}
