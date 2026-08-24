class AppConstants {
  static const appName = 'FaithPath';
  static const tagline = 'Bible Study & Companion';
  static const translation = 'King James Version (KJV)';
  static const translationShort = 'KJV';
  static const bibleAsset = 'assets/bible/en_kjv.json';

  static const highlightCategories = [
    'Faith',
    'Hope',
    'Love',
    'Prayer',
    'Wisdom',
    'Strength',
    'Personal',
  ];

  static const prayerCategories = [
    'Personal',
    'Family',
    'Friends',
    'School',
    'Work',
    'Other',
  ];

  static const prayerStatuses = ['Ongoing', 'Answered'];

  static const aiDisclaimer =
      'AI needs an internet connection. Explanations can contain errors. '
      'Scripture is the authority — verify important claims against the Bible '
      'and reliable study resources. Conversations sent to an AI provider leave this device.';

  static const privacyNote =
      'Personal prayers, reflections, notes, journal entries, bookmarks, '
      'and reading progress stay on this device unless you export them.';

  static const copyrightNote =
      'The King James Version (1769) is in the public domain. '
      'Bible text is stored separately from application logic so it can be replaced.';

  /// Default AI provider: Groq (OpenAI-compatible, free tier available).
  static const aiBaseUrl = 'https://api.groq.com/openai/v1';
  static const aiModel = 'llama-3.1-8b-instant';
  static const aiProviderLabel = 'Groq';
}

class HighlightLooks {
  static const colors = {
    'Faith': 0xFFC4A35A,
    'Hope': 0xFF4A90A4,
    'Love': 0xFFC45C6A,
    'Prayer': 0xFF7B6BA8,
    'Wisdom': 0xFF3D8B7A,
    'Strength': 0xFFD08A3A,
    'Personal': 0xFF5B8C5A,
  };
}
