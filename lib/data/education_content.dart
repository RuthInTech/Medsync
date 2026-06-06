import '../models/education_module.dart';
import '../models/enums.dart';

/// Catalogue of localized education modules and their text.
///
/// Each module's title/body resolves through [text] in the patient's language,
/// satisfying the "localized educational modules" requirement. English is the
/// fallback for any untranslated string.
class EducationContent {
  const EducationContent._();

  static const List<EducationModule> modules = [
    EducationModule(
      id: 'edu_diabetes_1',
      condition: ConditionType.diabetes,
      titleKey: 'diabetes_why_title',
      bodyKey: 'diabetes_why_body',
      readMinutes: 3,
    ),
    EducationModule(
      id: 'edu_hypertension_1',
      condition: ConditionType.hypertension,
      titleKey: 'htn_why_title',
      bodyKey: 'htn_why_body',
      readMinutes: 3,
    ),
    EducationModule(
      id: 'edu_hiv_1',
      condition: ConditionType.hiv,
      titleKey: 'hiv_why_title',
      bodyKey: 'hiv_why_body',
      readMinutes: 4,
    ),
    EducationModule(
      id: 'edu_tb_1',
      condition: ConditionType.tuberculosis,
      titleKey: 'tb_why_title',
      bodyKey: 'tb_why_body',
      readMinutes: 4,
    ),
    EducationModule(
      id: 'edu_chol_1',
      condition: ConditionType.highCholesterol,
      titleKey: 'chol_why_title',
      bodyKey: 'chol_why_body',
      readMinutes: 2,
    ),
  ];

  static List<EducationModule> forConditions(List<ConditionType> conditions) =>
      modules.where((m) => conditions.contains(m.condition)).toList();

  static String text(String key, AppLanguage lang) =>
      _content[lang.code]?[key] ?? _content['en']?[key] ?? key;

  static const Map<String, Map<String, String>> _content = {
    'en': {
      'diabetes_why_title': 'Why taking your diabetes pills daily matters',
      'diabetes_why_body':
          'Diabetes medication keeps your blood sugar steady. Skipping doses lets sugar climb silently, damaging your eyes, kidneys, and nerves over time. Take it at the same time each day — even when you feel fine, because high sugar often has no symptoms.',
      'htn_why_title': 'Controlling high blood pressure',
      'htn_why_body':
          'High blood pressure rarely hurts, but it quietly strains your heart and can cause a stroke. Daily medication keeps the pressure down. Never stop because you feel well — the medicine is what is keeping you well.',
      'hiv_why_title': 'Staying undetectable with HIV treatment',
      'hiv_why_body':
          'Taking your ART every single day keeps the virus so low it cannot be detected — and cannot be passed on. Missing doses lets the virus rebound and can build resistance. Consistency is your strongest protection.',
      'tb_why_title': 'Finishing your full TB course',
      'tb_why_body':
          'TB treatment must be completed in full, even after you feel better. Stopping early lets the bacteria return stronger and harder to treat. Every dose, all the way to the end, is what cures you.',
      'chol_why_title': 'Managing cholesterol',
      'chol_why_body':
          'Cholesterol medicine lowers the fatty buildup in your arteries, reducing your risk of heart attack. It works gradually and silently — daily consistency is what protects your heart.',
    },
    'am': {
      'diabetes_why_title': 'የስኳር መድኃኒትዎን በየቀኑ መውሰድ ለምን አስፈላጊ ነው',
      'diabetes_why_body':
          'የስኳር መድኃኒት የደምዎን ስኳር የተረጋጋ ያደርጋል። መድኃኒት መዝለል ስኳር በዝምታ እንዲጨምር በማድረግ ዓይኖችዎን፣ ኩላሊቶችዎን እና ነርቮችዎን ይጎዳል። ጤናማ ሲሰማዎትም እንኳ በየቀኑ በተመሳሳይ ሰዓት ይውሰዱት — ከፍተኛ ስኳር ብዙ ጊዜ ምልክት የለውም።',
      'htn_why_title': 'ከፍተኛ የደም ግፊትን መቆጣጠር',
      'htn_why_body':
          'ከፍተኛ የደም ግፊት ብዙ ጊዜ አያማም፣ ነገር ግን ልብዎን በዝምታ ያደክማል እንዲሁም የስትሮክ መንስኤ ሊሆን ይችላል። የዕለት ተዕለት መድኃኒት ግፊቱን ዝቅ ያደርጋል። ጤናማ ስለሚሰማዎት ብቻ በፍጹም አያቁሙ — መድኃኒቱ ነው ጤናማ የሚያደርግዎት።',
      'hiv_why_title': 'በኤች አይ ቪ ሕክምና የማይታወቅ ሆኖ መቆየት',
      'hiv_why_body':
          'የ ART መድኃኒትዎን በየቀኑ መውሰድ ቫይረሱን እስከ ማይታወቅ ድረስ ዝቅ ያደርጋል — እና ሊተላለፍ አይችልም። መድኃኒት መዝለል ቫይረሱ እንዲመለስ እና መቋቋም እንዲገነባ ያደርጋል። ቀጣይነት ጠንካራ ጥበቃዎ ነው።',
      'tb_why_title': 'ሙሉ የቲቢ ሕክምናዎን መጨረስ',
      'tb_why_body':
          'የቲቢ ሕክምና የተሻለ ሲሰማዎትም እንኳ ሙሉ በሙሉ መጠናቀቅ አለበት። ቀድሞ ማቆም ባክቴሪያው የበለጠ ጠንካራ ሆኖ እንዲመለስ ያደርጋል። እያንዳንዱ መድኃኒት እስከ መጨረሻው ድረስ የሚፈውስዎት ነው።',
      'chol_why_title': 'ኮሌስትሮልን መቆጣጠር',
      'chol_why_body':
          'የኮሌስትሮል መድኃኒት በደም ቧንቧዎችዎ ውስጥ ያለውን የስብ ክምችት ይቀንሳል፣ የልብ ድካም አደጋን ይቀንሳል። ቀስ በቀስ እና በዝምታ ይሰራል — የዕለት ተዕለት ቀጣይነት ልብዎን የሚጠብቅ ነው።',
    },
  };
}
