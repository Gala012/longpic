class HistoryRecord {
  final int? id;
  final String type;
  final String title;
  final String thumbnail;
  final String createdAt;
  const HistoryRecord({
    this.id,
    required this.type,
    required this.title,
    required this.thumbnail,
    required this.createdAt,
  });
  factory HistoryRecord.fromMap(Map<String, dynamic> map) {
    return HistoryRecord(
      id: map['id'] as int?,
      type: map['type'] as String,
      title: map['title'] as String,
      thumbnail: map['thumbnail'] as String,
      createdAt: map['created_at'] as String,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'title': title,
      'thumbnail': thumbnail,
      'created_at': createdAt,
    };
  }
}
