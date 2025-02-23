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
      'reviewed': isCompleted ? 1 : 0, // تحويل bool إلى int
    };
  }

  // إضافة دالة fromMap (اختياري، لكنها مفيدة)
  factory Sura.fromMap(Map<String, dynamic> map) {
    return Sura(
      id: map['id'] as int,
      name: map['name'] as String,
      pages: map['pages'] as double,
      isCompleted: map['reviewed'] == 1, // تحويل int إلى bool
    );
  }
}