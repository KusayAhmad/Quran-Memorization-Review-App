class Sura {
  final int id;
  final String name;
  final double pages;
  bool isCompleted;

  Sura({
    required this.id,
    required this.name,
    required this.pages,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'pages': pages,
    };
  }
}
