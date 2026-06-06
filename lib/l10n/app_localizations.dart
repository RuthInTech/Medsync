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
      'appName': 'Medisync',
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
      'fullName': 'Full name',
      'exploreDemo': 'Explore with demo data',
      'logout': 'Sign out',
      'logoutConfirm': 'Are you sure you want to sign out?',
    },
    'am': {
      'appName': 'Medisync',
      'tagline': 'በየቀኑ ጤናማ ይሁኑ',
      'today': 'ዛሬ',
      'dashboard': 'ዳሽቦርድ',
      'learn': 'ይማሩ',
      'report': 'ሪፖርት',
      'clinic': 'ክሊኒክ',
      'settings': 'ቅንብሮች',
      'streak': 'ተከታታይ ቀናት',
      'completion': 'መጠናቀቅ',
      'points': 'ነጥቦች',
      'dueNow': 'አሁን ይወሰዳል',
      'takeDose': 'መድኃኒት ይውሰዱ',
      'confirmDose': 'መድኃኒትዎን ያረጋግጡ',
      'proofPrompt': 'ይህን መድኃኒት እንዴት ማረጋገጥ ይፈልጋሉ?',
      'doseConfirmed': 'መድኃኒቱ ተረጋግጧል። በጣም ጥሩ!',
      'noDosesToday': 'ለዛሬ የተያዘ መድኃኒት የለም።',
      'allDone': 'ዛሬ ሁሉንም ጨርሰዋል!',
      'riskTitle': 'የመከተል አደጋ',
      'whyThis': 'ይህ ነጥብ ለምን',
      'educationFor': 'ትምህርት',
      'markRead': 'እንደተነበበ ምልክት አድርግ',
      'readAgain': 'እንደገና ያንብቡ',
      'shareReport': 'ከሐኪሜ ጋር አጋራ',
      'reportCopied': 'ሪፖርቱ ተቀድቷል',
      'language': 'ቋንቋ',
      'testReminder': 'የሙከራ ማስታወሻ ላክ',
      'reminderSent': 'ማስታወሻ ተልኳል',
      'flaggedPatients': 'ምልክት የተደረገባቸው ታካሚዎች',
      'allPatients': 'ሁሉም ታካሚዎች',
      'getStarted': 'ይጀምሩ',
      'welcomeBody':
          'ለሁሉም ሕክምናዎችዎ አንድ መተግበሪያ። እያንዳንዱን መድኃኒት ይከታተሉ፣ ተከታታይ ቀናትን ይገንቡ፣ እና ከጤናዎ ቀድመው ይራመዱ።',
      'minRead': 'ደቂቃ ንባብ',
      'fullName': 'ሙሉ ስም',
      'exploreDemo': 'ናሙና ዳታ ጋር ሞክሩ',
      'logout': 'ዘግቶ ውጣ',
      'logoutConfirm': 'እርግጠኛ ነዎት ዘግቶ መውጣት ይፈልጋሉ?',
    },
  };
}
