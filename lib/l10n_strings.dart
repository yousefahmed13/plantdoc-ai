class Str {
  final bool isAr;
  const Str(this.isAr);

  String get appName => 'PlantDoc AI';
  String get appTagline => isAr ? 'مستشار أمراض النبات الذكي' : 'AI Plant Pathology Advisor';

  String get settingsTitle => isAr ? 'إعدادات الخادم' : 'Server Settings';
  String get settingsHint => isAr ? 'رابط ngrok من Kaggle notebook' : 'ngrok URL from Kaggle notebook';
  String get settingsPlaceholder => 'https://xxxx.ngrok-free.app';
  String get settingsSave => isAr ? 'حفظ' : 'Save';
  String get settingsCancel => isAr ? 'إلغاء' : 'Cancel';
  String get settingsTest => isAr ? 'اختبار الاتصال' : 'Test Connection';
  String get settingsConnected => isAr ? '✅ متصل بالخادم' : '✅ Connected';
  String get settingsDisconnected => isAr ? '❌ تعذّر الاتصال' : '❌ Connection failed';
  String get settingsDesc => isAr
      ? 'الصق رابط الـ ngrok من خلية Section 13C في Kaggle notebook:'
      : 'Paste the ngrok URL from Section 13C in your Kaggle notebook:';

  String get online => isAr ? 'متصل' : 'Online';
  String get offline => isAr ? 'غير متصل' : 'Offline';

  String get analyzeBtn => isAr ? 'بدء التحليل' : 'Analyze Now';
  String get analyzing => isAr ? 'جاري التحليل...' : 'Analyzing...';
  String get pickImage => isAr ? 'اختر صورة' : 'Pick Image';
  String get camera => isAr ? 'الكاميرا' : 'Camera';
  String get gallery => isAr ? 'المعرض' : 'Gallery';
  String get plantName => isAr ? 'اسم النبات (اختياري)' : 'Plant name (optional)';
  String get plantHint => isAr ? 'مثل: طماطم، عنب، قمح' : 'e.g. tomato, grape, wheat';
  String get weatherSection => isAr ? 'بيانات الطقس والتربة (اختياري)' : 'Weather & Soil Data (optional)';
  String get tempLabel => isAr ? 'الحرارة (°C)' : 'Temp (°C)';
  String get humidLabel => isAr ? 'الرطوبة (%)' : 'Humidity (%)';
  String get soilLabel => isAr ? 'رطوبة التربة (%)' : 'Soil Moisture (%)';
  String get stageLabel => isAr ? 'مرحلة النمو' : 'Growth Stage';
  String get seasonLabel => isAr ? 'الموسم' : 'Season';
  String get irrigationMode => isAr ? 'وضع الري فقط (بدون صورة)' : 'Irrigation-only mode (no image)';

  String get msgPlaceholder => isAr ? 'اكتب سؤالاً...' : 'Ask something...';
  String get send => isAr ? 'إرسال' : 'Send';
  String get newChat => isAr ? 'محادثة جديدة' : 'New Chat';
  String get clearConfirm => isAr ? 'هل تريد بدء محادثة جديدة؟' : 'Start a new conversation?';
  String get clearYes => isAr ? 'نعم' : 'Yes';
  String get clearNo => isAr ? 'لا' : 'No';

  String get greeting => isAr
      ? 'مرحباً! أنا PlantDoc AI 🌿\n\nيمكنك:\n• رفع صورة ورقة نبات أو حشرة للتشخيص\n• إدخال بيانات طقس للحصول على توصية الري\n• سؤالي عن أي مرض أو آفة نباتية\n\nاضغط 📷 لرفع صورة والبدء.'
      : 'Hello! I\'m PlantDoc AI 🌿\n\nYou can:\n• Upload a plant leaf or insect image for diagnosis\n• Enter weather data for smart irrigation advice\n• Ask me about any plant disease or pest\n\nTap 📷 to upload an image and start.';

  String get noServerMsg => isAr
      ? 'يرجى ضبط رابط الخادم أولاً.\nاضغط ⚙️ وأدخل رابط ngrok من Kaggle notebook.'
      : 'Please set the server URL first.\nTap ⚙️ and enter the ngrok URL from your Kaggle notebook.';

  String get connectionError => isAr
      ? 'تعذّر الاتصال. تأكد أن Kaggle notebook شغّال ورابط ngrok صحيح.'
      : 'Connection failed. Make sure the Kaggle notebook is running and the ngrok URL is correct.';

  String get fullReport => isAr ? 'التقرير الكامل' : 'Full Report';
  String get whatDisease => isAr ? 'ما المرض؟' : 'What disease?';
  String get treatment => isAr ? 'العلاج؟' : 'Treatment?';
  String get prevention => isAr ? 'الوقاية؟' : 'Prevention?';
  String get irrigationQ => isAr ? 'توصية الري؟' : 'Irrigation?';
  String get whatInsect => isAr ? 'ما الحشرة؟' : 'What insect?';
  String get moreDetails => isAr ? 'تفاصيل أكثر' : 'More details';

  String get tapToAnalyze => isAr ? 'اضغط للتحليل' : 'Tap to analyze';
  String get imageSelected => isAr ? 'تم اختيار الصورة' : 'Image selected';
  String get imageRequired => isAr ? 'يرجى اختيار صورة أو إدخال بيانات الطقس' : 'Please pick an image or enter weather data';

  List<String> get growthStages =>
      ['Germination', 'Vegetative', 'Flowering', 'Fruiting', 'Harvesting'];
  List<String> get seasons =>
      ['Spring', 'Summer', 'Autumn', 'Winter', 'Rabi', 'Kharif'];

  String growthStageAr(String s) {
    const m = {
      'Germination': 'الإنبات',
      'Vegetative': 'خضري',
      'Flowering': 'تزهير',
      'Fruiting': 'إثمار',
      'Harvesting': 'حصاد',
    };
    return isAr ? (m[s] ?? s) : s;
  }

  String seasonAr(String s) {
    const m = {
      'Spring': 'ربيع',
      'Summer': 'صيف',
      'Autumn': 'خريف',
      'Winter': 'شتاء',
      'Rabi': 'شتوي (ربيعي)',
      'Kharif': 'صيفي (خريفي)',
    };
    return isAr ? (m[s] ?? s) : s;
  }
}
