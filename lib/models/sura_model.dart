class Sura {
  final int id;
  final String name;
  final int pages;
  bool isCompleted;
  DateTime? lastReadDate;

  Sura({
    required this.id,
    required this.name,
    required this.pages,
    this.isCompleted = false,
    this.lastReadDate,
  });

  factory Sura.fromJson(Map<String, dynamic> json) => Sura(
    id: json['id'],
    name: json['name'],
    pages: json['pages'],
    isCompleted: json['isCompleted'] ?? false,
    lastReadDate: json['lastReadDate'] == null
        ? null
        : DateTime.tryParse(json['lastReadDate']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'pages': pages,
    'isCompleted': isCompleted,
    'lastReadDate': lastReadDate?.toIso8601String(),
  };
}
