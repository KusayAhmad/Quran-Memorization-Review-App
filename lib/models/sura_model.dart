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
}