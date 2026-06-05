import 'package:flutter/widgets.dart';

import '../models/enums.dart';

/// Lightweight in-app localization keyed by [AppLanguage].
///
/// Deliberately self-contained (no codegen/ARB) so content — including the
/// education modules — can be translated and shipped as plain Dart maps. The
/// active language follows the patient's profile setting, falling back to
/// English for any missing key.
class AppLocalizations {
  AppLocalizations(this.language);

  final AppLanguage language;

  static AppLocalizations of(BuildContext context, AppLanguage language) =>
      AppLocalizations(language);

  String t(String key) {
    return _strings[language.code]?[key] ??
        _strings['en']?[key] ??
        key;
  }

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'appName': 'Siyaphila',
      'tagline': 'Stay well, every day',
      'today': 'Today',
      'dashboard': 'Dashboard',
      'learn': 'Learn',
      'report': 'Report',
      'clinic': 'Clinic',
      'settings': 'Settings',
      'streak': 'day streak',
      'completion': 'Completion',
      'points': 'points',
      'dueNow': 'Due now',
      'takeDose': 'Take dose',
      'confirmDose': 'Confirm your dose',
      'proofPrompt': 'How would you like to verify this dose?',
      'doseConfirmed': 'Dose confirmed. Well done!',
      'noDosesToday': 'No doses scheduled for today.',
      'allDone': "You're all caught up today!",
      'riskTitle': 'Adherence risk',
      'whyThis': 'Why this score',
      'educationFor': 'Education',
      'markRead': 'Mark as read',
      'readAgain': 'Read again',
      'shareReport': 'Share with my doctor',
      'reportCopied': 'Report copied to clipboard',
      'language': 'Language',
      'testReminder': 'Send a test reminder',
      'reminderSent': 'Reminder sent',
      'flaggedPatients': 'Flagged patients',
      'allPatients': 'All patients',
      'getStarted': 'Get started',
      'welcomeBody':
          'One app for all your treatments. Track every dose, build streaks, and stay ahead of your health.',
      'minRead': 'min read',
    },
    'zu': {
      'appName': 'Siyaphila',
      'tagline': 'Hlala uphilile, nsuku zonke',
      'today': 'Namuhla',
      'dashboard': 'Ibhodi',
      'learn': 'Funda',
      'report': 'Umbiko',
      'clinic': 'Umtholampilo',
      'settings': 'Izilungiselelo',
      'streak': 'izinsuku zilandelana',
      'completion': 'Ukuqedela',
      'points': 'amaphuzu',
      'dueNow': 'Kufanele manje',
      'takeDose': 'Thatha umuthi',
      'confirmDose': 'Qinisekisa umuthi wakho',
      'proofPrompt': 'Ungathanda ukuqinisekisa kanjani lo muthi?',
      'doseConfirmed': 'Umuthi uqinisekisiwe. Wenze kahle!',
      'noDosesToday': 'Ayikho imithi ehleliwe namuhla.',
      'allDone': 'Usuqede konke namuhla!',
      'riskTitle': 'Ingozi yokungalandeli',
      'whyThis': 'Kungani leli phuzu',
      'educationFor': 'Imfundo',
      'markRead': 'Maka njengokufundiwe',
      'readAgain': 'Funda futhi',
      'shareReport': 'Yabelana nodokotela wami',
      'reportCopied': 'Umbiko ukopishelwe',
      'language': 'Ulimi',
      'testReminder': 'Thumela isikhumbuzo sokuhlola',
      'reminderSent': 'Isikhumbuzo sithunyelwe',
      'flaggedPatients': 'Iziguli ezimakiwe',
      'allPatients': 'Zonke iziguli',
      'getStarted': 'Qalisa',
      'welcomeBody':
          'Uhlelo olulodwa lwakho konke ukwelashwa. Landelela wonke umuthi, wakhe izinsuku zilandelana, uhlale uphambili kwezempilo.',
      'minRead': 'imizuzu yokufunda',
    },
    'xh': {
      'appName': 'Siyaphila',
      'tagline': 'Hlala usempilweni, yonke imihla',
      'today': 'Namhlanje',
      'dashboard': 'Ideshbhodi',
      'learn': 'Funda',
      'report': 'Ingxelo',
      'clinic': 'Ikliniki',
      'settings': 'Iisetingi',
      'streak': 'iintsuku ngokulandelelana',
      'completion': 'Ukugqiba',
      'points': 'amanqaku',
      'dueNow': 'Kufuneka ngoku',
      'takeDose': 'Thatha iyeza',
      'confirmDose': 'Qinisekisa iyeza lakho',
      'proofPrompt': 'Ungathanda ukuqinisekisa njani eli yeza?',
      'doseConfirmed': 'Iyeza liqinisekisiwe. Wenze kakuhle!',
      'noDosesToday': 'Akukho mayeza acwangcisiweyo namhlanje.',
      'allDone': 'Sele ugqibile namhlanje!',
      'riskTitle': 'Umngcipheko wokungathobeli',
      'whyThis': 'Kutheni eli nqaku',
      'educationFor': 'Imfundo',
      'markRead': 'Phawula njengoxeliweyo',
      'readAgain': 'Funda kwakhona',
      'shareReport': 'Yabelana nogqirha wam',
      'reportCopied': 'Ingxelo ikhutshelwe',
      'language': 'Ulwimi',
      'testReminder': 'Thumela isikhumbuzo sovavanyo',
      'reminderSent': 'Isikhumbuzo sithunyelwe',
      'flaggedPatients': 'Izigulane eziphawuliweyo',
      'allPatients': 'Zonke izigulane',
      'getStarted': 'Qalisa',
      'welcomeBody':
          'Usebenziso olunye lwawo onke amayeza akho. Landela lonke iyeza, wakhe iintsuku ngokulandelelana, uhlale uphambili kwimpilo.',
      'minRead': 'imizuzu yokufunda',
    },
    'af': {
      'appName': 'Siyaphila',
      'tagline': 'Bly gesond, elke dag',
      'today': 'Vandag',
      'dashboard': 'Paneelbord',
      'learn': 'Leer',
      'report': 'Verslag',
      'clinic': 'Kliniek',
      'settings': 'Instellings',
      'streak': 'dae streep',
      'completion': 'Voltooiing',
      'points': 'punte',
      'dueNow': 'Nou verskuldig',
      'takeDose': 'Neem dosis',
      'confirmDose': 'Bevestig jou dosis',
      'proofPrompt': 'Hoe wil jy hierdie dosis verifieer?',
      'doseConfirmed': 'Dosis bevestig. Mooi so!',
      'noDosesToday': 'Geen dosisse vir vandag geskeduleer nie.',
      'allDone': 'Jy is heeltemal op datum vandag!',
      'riskTitle': 'Nakomingsrisiko',
      'whyThis': 'Hoekom hierdie telling',
      'educationFor': 'Opvoeding',
      'markRead': 'Merk as gelees',
      'readAgain': 'Lees weer',
      'shareReport': 'Deel met my dokter',
      'reportCopied': 'Verslag gekopieer',
      'language': 'Taal',
      'testReminder': "Stuur 'n toetsherinnering",
      'reminderSent': 'Herinnering gestuur',
      'flaggedPatients': 'Gemerkte pasiënte',
      'allPatients': 'Alle pasiënte',
      'getStarted': 'Begin',
      'welcomeBody':
          'Een app vir al jou behandelings. Hou elke dosis dop, bou strepe, en bly jou gesondheid voor.',
      'minRead': 'min lees',
    },
  };
}
