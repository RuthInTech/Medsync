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
    'zu': {
      'diabetes_why_title': 'Kungani kubalulekile ukuphuza amaphilisi esifo sikashukela nsuku zonke',
      'diabetes_why_body':
          'Umuthi kashukela ugcina ushukela wegazi ulinganisekile. Ukweqa imithi kuvumela ushukela ukhuphuke ngokuthula, ulimaze amehlo, izinso, nezinzwa. Wuthathe ngesikhathi esifanayo nsuku zonke — noma uzizwa kahle.',
      'htn_why_title': 'Ukulawula umfutho wegazi ophezulu',
      'htn_why_body':
          'Umfutho wegazi ophezulu awuvami ukuzwakala, kodwa ucindezela inhliziyo futhi ungabangela isifo sohlangothi. Umuthi wansuku zonke uwehlisa. Ungayeki ngoba uzizwa kahle.',
      'hiv_why_title': 'Ukuhlala ungatholakali ngokwelashwa kwe-HIV',
      'hiv_why_body':
          'Ukuphuza ama-ARV mihla yonke kugcina igciwane liphansi kangangokuthi alitholakali — futhi alidluliseki. Ukweqa imithi kuvumela igciwane libuye futhi kwakhe ukumelana.',
      'tb_why_title': 'Qedela uhlelo lwakho lwe-TB lonke',
      'tb_why_body':
          'Ukwelashwa kwe-TB kufanele kuqedwe ngokugcwele, noma usuzizwa ungcono. Ukuyeka kusenesikhathi kuvumela amagciwane abuye eqine. Wonke umuthi, kuze kube sekugcineni, yiwo okwelaphayo.',
      'chol_why_title': 'Ukulawula i-cholesterol',
      'chol_why_body':
          'Umuthi we-cholesterol wehlisa amafutha emithanjeni yakho, unciphisa ingozi yokuhlaselwa yinhliziyo. Usebenza kancane futhi ngokuthula — ukungaguquki nsuku zonke yikho okuvikela inhliziyo.',
    },
    'xh': {
      'diabetes_why_title': 'Kutheni kubalulekile ukusela amayeza eswekile yonke imihla',
      'diabetes_why_body':
          'Iyeza leswekile ligcina iswekile yegazi izinzile. Ukutsiba amayeza kuvumela iswekile inyuke ngokuthe cwaka, yonakalise amehlo, izintso, neminwe. Lithathe ngexesha elinye yonke imihla.',
      'htn_why_title': 'Ukulawula uxinzelelo lwegazi oluphezulu',
      'htn_why_body':
          'Uxinzelelo lwegazi oluphezulu aludli, kodwa luxina intliziyo lunokubangela istroke. Iyeza lemihla ngemihla luyalwehlisa. Sukuyeka kuba uziva ngcono.',
      'hiv_why_title': 'Ukuhlala ungafumaneki ngonyango lwe-HIV',
      'hiv_why_body':
          'Ukusela ama-ARV yonke imihla kugcina intsholongwane isezantsi kangangokuba ayifumaneki — ingadluliseki. Ukutsiba amayeza kuvumela intsholongwane ibuye.',
      'tb_why_title': 'Gqibezela lonke unyango lwakho lwe-TB',
      'tb_why_body':
          'Unyango lwe-TB kufuneka lugqitywe ngokupheleleyo, nokuba uziva ngcono. Ukuyeka kwangethuba kuvumela iibhaktiriya zibuye zomelele. Lonke iyeza, kude kuse ekugqibeleni, yiyo into ekuphilisayo.',
      'chol_why_title': 'Ukulawula i-cholesterol',
      'chol_why_body':
          'Iyeza le-cholesterol lehlisa amafutha kwimithambo yakho, linciphisa umngcipheko wokuhlaselwa yintliziyo. Lisebenza ngokuthe ngcembe — ukungaguquguquki yonke imihla kukho okukhusela intliziyo.',
    },
    'af': {
      'diabetes_why_title': 'Hoekom dit saak maak om jou diabetespille daagliks te neem',
      'diabetes_why_body':
          'Diabetesmedikasie hou jou bloedsuiker stabiel. Om dosisse oor te slaan laat suiker stil styg en beskadig jou oë, niere en senuwees. Neem dit elke dag op dieselfde tyd — selfs wanneer jy goed voel.',
      'htn_why_title': 'Beheer van hoë bloeddruk',
      'htn_why_body':
          'Hoë bloeddruk maak selde seer, maar dit belas stil jou hart en kan ’n beroerte veroorsaak. Daaglikse medikasie hou die druk laag. Hou nooit op omdat jy goed voel nie.',
      'hiv_why_title': 'Bly onopspoorbaar met MIV-behandeling',
      'hiv_why_body':
          'Om jou ARV’s elke dag te neem hou die virus so laag dat dit nie opgespoor kan word nie — en nie oorgedra kan word nie. Gemiste dosisse laat die virus terugkeer en bou weerstand.',
      'tb_why_title': 'Voltooi jou volle TB-kursus',
      'tb_why_body':
          'TB-behandeling moet ten volle voltooi word, selfs nadat jy beter voel. Om vroeg op te hou laat die bakterieë sterker terugkom. Elke dosis, heel tot die einde, is wat jou genees.',
      'chol_why_title': 'Bestuur van cholesterol',
      'chol_why_body':
          'Cholesterolmedikasie verlaag die vetterige opbou in jou are en verminder jou risiko vir ’n hartaanval. Dit werk geleidelik — daaglikse konsekwentheid beskerm jou hart.',
    },
  };
}
