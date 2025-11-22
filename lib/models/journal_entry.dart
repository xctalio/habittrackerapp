class JournalEntry {
  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime dateEntry;

  JournalEntry({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.dateEntry,
  });
}