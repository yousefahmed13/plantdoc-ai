import 'package:flutter/material.dart';
import '../models/disease_info.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class DictionaryScreen extends StatefulWidget {
  final String lang;
  const DictionaryScreen({Key? key, required this.lang}) : super(key: key);

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final TextEditingController _localSearch = TextEditingController();
  final TextEditingController _onlineSearch = TextEditingController();
  String _cropFilter = 'all';
  List<MapEntry<String, DiseaseInfo>> _localResults = [];
  bool _onlineLoading = false;
  List<dynamic> _onlineResults = [];
  String? _onlineError;

  final _crops = ['all', 'Apple', 'Corn', 'Grape', 'Orange', 'Peach', 'Potato', 'Tomato', 'Wheat'];
  final _cropAr = {
    'all': 'الكل', 'Apple': 'تفاح', 'Corn': 'ذرة', 'Grape': 'عنب',
    'Orange': 'برتقال', 'Peach': 'خوخ', 'Potato': 'بطاطس', 'Tomato': 'طماطم', 'Wheat': 'قمح',
  };

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _filterLocal();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _localSearch.dispose();
    _onlineSearch.dispose();
    super.dispose();
  }

  void _filterLocal() {
    final q = _localSearch.text.toLowerCase();
    setState(() {
      _localResults = diseaseDictionary.entries.where((e) {
        final info = e.value;
        final matchCrop = _cropFilter == 'all' ||
            info.plantNameEn.toLowerCase() == _cropFilter.toLowerCase();
        final matchQ = q.isEmpty ||
            e.key.toLowerCase().contains(q) ||
            info.plantNameEn.toLowerCase().contains(q) ||
            info.plantNameAr.contains(q) ||
            info.conditionEn.toLowerCase().contains(q) ||
            info.conditionAr.contains(q);
        return matchCrop && matchQ;
      }).toList();
    });
  }

  Future<void> _searchOnline() async {
    final q = _onlineSearch.text.trim();
    if (q.isEmpty) return;
    setState(() { _onlineLoading = true; _onlineError = null; _onlineResults = []; });
    try {
      final sessionId = await ApiService.getSessionId();
      if (sessionId == null || sessionId.isEmpty) {
        throw Exception(widget.lang == 'ar'
            ? 'يرجى تشخيص صورة أولاً لاستخدام البحث الذكي'
            : 'Please diagnose an image first to use AI search');
      }
      final res = await ApiService.chat(sessionId: sessionId, message: q);
      final reply = res['reply']?.toString() ?? '';
      setState(() => _onlineResults =
          reply.isNotEmpty ? [{'title': 'AgroVision AI', 'content': reply}] : []);
    } catch (e) {
      setState(() => _onlineError = e.toString().replaceAll('Exception:', '').trim());
    } finally {
      setState(() => _onlineLoading = false);
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
          title: Text(isAr ? 'قاموس الأمراض' : 'Disease Dictionary',
              style: appFont(isAr, size: 16, weight: FontWeight.w700)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            controller: _tabs,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(text: isAr ? 'قاعدة البيانات' : 'Local Database'),
              Tab(text: isAr ? 'البحث الشامل' : 'Online Search'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabs,
          children: [_buildLocalTab(isAr), _buildOnlineTab(isAr)],
        ),
      ),
    );
  }

  Widget _buildLocalTab(bool isAr) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
            controller: _localSearch,
            onChanged: (_) => _filterLocal(),
            style: appFont(isAr, size: 14),
            decoration: InputDecoration(
              hintText: isAr ? 'ابحث عن مرض أو نبات...' : 'Search disease or plant...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
              suffixIcon: _localSearch.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 18),
                      onPressed: () { _localSearch.clear(); _filterLocal(); },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _crops.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final c = _crops[i];
                final selected = _cropFilter == c;
                return GestureDetector(
                  onTap: () { setState(() => _cropFilter = c); _filterLocal(); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: selected ? AppColors.primary : AppColors.cardBorder),
                    ),
                    child: Text(
                      isAr ? (_cropAr[c] ?? c) : c,
                      style: appFont(isAr, size: 11, weight: FontWeight.w600,
                          color: selected ? Colors.white : AppColors.textSecondary),
                    ),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
      Expanded(
        child: _localResults.isEmpty
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text(isAr ? 'لا توجد نتائج' : 'No results found',
                      style: appFont(isAr, size: 14, color: AppColors.textMuted)),
                ]),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: _localResults.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) => _buildDiseaseCard(_localResults[i], isAr),
              ),
      ),
    ]);
  }

  Widget _buildDiseaseCard(MapEntry<String, DiseaseInfo> entry, bool isAr) {
    final info = entry.value;
    final isHealthy = entry.key.toLowerCase().contains('healthy');
    return GestureDetector(
      onTap: () => _showDiseaseDetail(entry, isAr),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: (isHealthy ? AppColors.primary : AppColors.amber).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isHealthy ? Icons.check_circle_rounded : Icons.bug_report_rounded,
              color: isHealthy ? AppColors.primary : AppColors.amber,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isAr ? info.plantNameAr : info.plantNameEn,
                  style: appFont(isAr, size: 13, weight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(isAr ? info.conditionAr : info.conditionEn,
                  style: appFont(isAr, size: 11, color: AppColors.textSecondary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          Icon(isAr ? Icons.arrow_back_ios_rounded : Icons.arrow_forward_ios_rounded,
              size: 14, color: AppColors.textMuted),
        ]),
      ),
    );
  }

  void _showDiseaseDetail(MapEntry<String, DiseaseInfo> entry, bool isAr) {
    final info = entry.value;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: DraggableScrollableSheet(
          initialChildSize: 0.7, maxChildSize: 0.95, minChildSize: 0.4, expand: false,
          builder: (ctx, sc) => SingleChildScrollView(
            controller: sc,
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: AppColors.cardBorder, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(
                isAr
                    ? '${info.plantNameAr} — ${info.conditionAr}'
                    : '${info.plantNameEn} — ${info.conditionEn}',
                style: appFont(isAr, size: 18, weight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              _detailSection(
                  isAr ? 'الأعراض' : 'Symptoms',
                  isAr ? info.symptomsAr : info.symptomsEn,
                  Icons.search_rounded, AppColors.blue, isAr),
              const SizedBox(height: 14),
              _detailSection(
                  isAr ? 'العلاج والمكافحة' : 'Treatment & Control',
                  isAr ? info.treatmentAr : info.treatmentEn,
                  Icons.healing_rounded, AppColors.primary, isAr),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _detailSection(String title, String body, IconData icon, Color color, bool isAr) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(title, style: appFont(isAr, size: 12, weight: FontWeight.w700, color: color)),
        ]),
        const SizedBox(height: 8),
        Text(body, style: appFont(isAr, size: 12, color: AppColors.textSecondary, height: 1.6)),
      ]),
    );
  }

  Widget _buildOnlineTab(bool isAr) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: _onlineSearch,
              style: appFont(isAr, size: 14),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchOnline(),
              decoration: InputDecoration(
                hintText: isAr ? 'ابحث في قاعدة البيانات الشاملة...' : 'Search unified database...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _searchOnline,
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.search_rounded, color: Colors.white, size: 22),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        if (_onlineLoading)
          LoadingOverlay(
              message: isAr ? 'جاري البحث في قاعدة البيانات...' : 'Searching database...', isAr: isAr)
        else if (_onlineError != null)
          ErrorBox(message: _onlineError!, isAr: isAr)
        else if (_onlineResults.isEmpty && _onlineSearch.text.isNotEmpty)
          Center(child: Text(isAr ? 'لا توجد نتائج' : 'No results found',
              style: appFont(isAr, size: 14, color: AppColors.textMuted)))
        else
          Expanded(
            child: ListView.separated(
              itemCount: _onlineResults.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final r = _onlineResults[i];
                return AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r['title']?.toString() ?? r['className']?.toString() ?? '—',
                        style: appFont(isAr, size: 13, weight: FontWeight.w700, color: AppColors.primary)),
                    const SizedBox(height: 6),
                    Text(r['content']?.toString() ?? r['description']?.toString() ?? '',
                        style: appFont(isAr, size: 11, color: AppColors.textSecondary, height: 1.5),
                        maxLines: 5, overflow: TextOverflow.ellipsis),
                  ]),
                );
              },
            ),
          ),
      ]),
    );
  }
}
