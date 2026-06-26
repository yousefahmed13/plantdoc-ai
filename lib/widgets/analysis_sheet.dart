import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cross_file/cross_file.dart';
import '../theme/plantdoc_theme.dart';
import '../l10n_strings.dart';

class AnalysisSheet extends StatefulWidget {
  final bool isAr;
  final Future<void> Function({
    XFile? imageFile,
    String plantName,
    double? temperatureC,
    double? humidity,
    double? soilMoisture,
    String? cropGrowthStage,
    String? season,
  }) onAnalyze;

  const AnalysisSheet({Key? key, required this.isAr, required this.onAnalyze})
      : super(key: key);

  @override
  State<AnalysisSheet> createState() => _AnalysisSheetState();
}

class _AnalysisSheetState extends State<AnalysisSheet> {
  XFile? _imageFile;
  Uint8List? _imageBytes;
  final _picker = ImagePicker();
  final _plantCtrl = TextEditingController();
  bool _showWeather = false;
  bool _analyzing = false;

  double _temp = 28;
  double _humidity = 55;
  double _soil = 45;
  String _stage = 'Vegetative';
  String _season = 'Summer';

  bool get _canAnalyze => _imageFile != null || _showWeather;

  @override
  void dispose() {
    _plantCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource src) async {
    try {
      final f = await _picker.pickImage(
        source: src,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (f != null) {
        final bytes = await f.readAsBytes();
        setState(() {
          _imageFile = f;
          _imageBytes = bytes;
        });
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_canAnalyze || _analyzing) return;
    setState(() => _analyzing = true);
    try {
      await widget.onAnalyze(
        imageFile: _imageFile,
        plantName: _plantCtrl.text.trim(),
        temperatureC: _showWeather ? _temp : null,
        humidity: _showWeather ? _humidity : null,
        soilMoisture: _showWeather ? _soil : null,
        cropGrowthStage: _showWeather ? _stage : null,
        season: _showWeather ? _season : null,
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Str(widget.isAr);
    final isAr = widget.isAr;
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: PD.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: PD.border)),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _handle(),
              const SizedBox(height: 16),
              _sectionTitle(isAr ? '📷 الصورة' : '📷 Image', isAr),
              const SizedBox(height: 10),
              _imageZone(s, isAr),
              const SizedBox(height: 14),
              TextField(
                controller: _plantCtrl,
                style: pdFont(isAr, size: 13),
                decoration: InputDecoration(
                  hintText: s.plantHint,
                  labelText: s.plantName,
                  labelStyle: pdFont(isAr, size: 12, color: PD.textSecondary),
                  prefixIcon: const Icon(Icons.eco_rounded, size: 18, color: PD.textMuted),
                ),
              ),
              const SizedBox(height: 14),
              _weatherToggle(s, isAr),
              if (_showWeather) ...[
                const SizedBox(height: 12),
                _weatherFields(s, isAr),
              ],
              const SizedBox(height: 20),
              _analyzeBtn(s, isAr),
            ],
          ),
        ),
      ),
    );
  }

  Widget _handle() => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: PD.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _sectionTitle(String text, bool isAr) => Text(
        text,
        style: pdFont(isAr, size: 13, weight: FontWeight.w700, color: PD.green),
      );

  Widget _imageZone(Str s, bool isAr) {
    return Column(
      children: [
        if (_imageBytes != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(
                _imageBytes!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: _pickBtn(Icons.camera_alt_rounded, s.camera, PD.green,
                  () => _pick(ImageSource.camera)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _pickBtn(Icons.photo_library_rounded, s.gallery, PD.blue,
                  () => _pick(ImageSource.gallery)),
            ),
          ],
        ),
        if (_imageFile != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, size: 13, color: PD.green),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _imageFile!.name.isNotEmpty ? _imageFile!.name : s.imageSelected,
                  style: pdFont(isAr, size: 11, color: PD.green),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  _imageFile = null;
                  _imageBytes = null;
                }),
                child: const Icon(Icons.close_rounded, size: 14, color: PD.textMuted),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _pickBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _weatherToggle(Str s, bool isAr) {
    return GestureDetector(
      onTap: () => setState(() => _showWeather = !_showWeather),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _showWeather ? PD.blue.withOpacity(0.08) : PD.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: _showWeather ? PD.blue.withOpacity(0.25) : PD.border),
        ),
        child: Row(
          children: [
            Icon(Icons.water_drop_rounded,
                size: 18, color: _showWeather ? PD.blue : PD.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(s.irrigationMode,
                  style: pdFont(isAr, size: 12,
                      color: _showWeather ? PD.blue : PD.textSecondary)),
            ),
            Icon(
                _showWeather
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                color: PD.textMuted,
                size: 18),
          ],
        ),
      ),
    );
  }

  Widget _weatherFields(Str s, bool isAr) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PD.blue.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PD.blue.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          _slider(s.tempLabel, _temp, 0, 50, '°C', PD.amber,
              (v) => setState(() => _temp = v), isAr),
          _slider(s.humidLabel, _humidity, 0, 100, '%', PD.blue,
              (v) => setState(() => _humidity = v), isAr),
          _slider(s.soilLabel, _soil, 0, 100, '%', PD.green,
              (v) => setState(() => _soil = v), isAr),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _dropdown(s.stageLabel, _stage, s.growthStages,
                      s.growthStageAr, (v) => setState(() => _stage = v!), isAr)),
              const SizedBox(width: 10),
              Expanded(
                  child: _dropdown(s.seasonLabel, _season, s.seasons,
                      s.seasonAr, (v) => setState(() => _season = v!), isAr)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _slider(String label, double val, double min, double max, String unit,
      Color color, ValueChanged<double> onChanged, bool isAr) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: pdFont(isAr, size: 11, color: PD.textSecondary)),
            Text('${val.toStringAsFixed(0)}$unit',
                style: pdFont(false,
                    size: 11, weight: FontWeight.w700, color: color)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: color,
            overlayColor: color.withOpacity(0.12),
            inactiveTrackColor: PD.border,
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(value: val, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _dropdown(String label, String val, List<String> items,
      String Function(String) translator, ValueChanged<String?> onChanged, bool isAr) {
    return DropdownButtonFormField<String>(
      value: val,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: pdFont(isAr, size: 11, color: PD.textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      dropdownColor: PD.card,
      style: pdFont(isAr, size: 12),
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(translator(e), style: pdFont(isAr, size: 12)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _analyzeBtn(Str s, bool isAr) {
    final can = _canAnalyze && !_analyzing;
    return GestureDetector(
      onTap: can ? _submit : null,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: can
              ? const LinearGradient(
                  colors: [PD.greenDark, PD.green],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: can ? null : PD.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: can ? PD.green.withOpacity(0.3) : PD.border),
        ),
        child: _analyzing
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.biotech_rounded,
                      color: can ? Colors.white : PD.textMuted, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    s.analyzeBtn,
                    style: pdFont(isAr,
                        size: 15,
                        weight: FontWeight.w800,
                        color: can ? Colors.white : PD.textMuted),
                  ),
                ],
              ),
      ),
    );
  }
}
