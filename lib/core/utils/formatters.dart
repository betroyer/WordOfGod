String greetingFor(DateTime now) {
  final hour = now.hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

String verseRef(String book, int chapter, int verse) => '$book $chapter:$verse';

String chapterRef(String book, int chapter) => '$book $chapter';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
