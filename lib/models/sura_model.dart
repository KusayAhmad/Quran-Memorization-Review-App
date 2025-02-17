class Sura {
  final int id;
  final String name;
  final int pages;
  bool isCompleted;

  Sura({
    required this.id,
    required this.name,
    required this.pages,
    this.isCompleted = false,
  });

  factory Sura.fromJson(Map<String, dynamic> json) => Sura(
    id: json['id'],
    name: json['name'],
    pages: json['pages'],
    isCompleted: json['isCompleted'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'pages': pages,
    'isCompleted': isCompleted,
  };
}