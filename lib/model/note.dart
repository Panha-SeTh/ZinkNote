class Note {
  final String id;
  String title;
  String body;
  final DateTime createdAt;
  DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    this.body = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  void editContent(String newTitle, String newBody) {
    title = newTitle;
    body = newBody;
    final now = DateTime.now();
    updatedAt = now.isAfter(updatedAt)
        ? now
        : updatedAt.add(const Duration(microseconds: 1));
  }
}
