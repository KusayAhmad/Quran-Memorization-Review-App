import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:quran_review_app/models/sura_model.dart';

class DatabaseHelper {
  static final _databaseName = "QuranReview.db";
  static final _databaseVersion = 1;

  static final tableSuras = 'suras';
  static final columnId = 'id';
  static final columnName = 'name';
  static final columnPages = 'pages';

  static final tableProgress = 'daily_progress';
  static final columnDate = 'date';
  static final columnCompleted = 'completed_suras';

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableSuras (
        $columnId INTEGER PRIMARY KEY,
        $columnName TEXT NOT NULL,
        $columnPages INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableProgress (
        $columnDate TEXT PRIMARY KEY,
        $columnCompleted TEXT NOT NULL
      )
    ''');
    // Add a table to store selected suras
    await db.execute('''
  CREATE TABLE selected_suras (
    id INTEGER ,
    name TEXT NOT NULL,
    pages INTEGER NOT NULL,
    reviewed BOOLEAN DEFAULT 0,
    FOREIGN KEY (id) REFERENCES suras(id)
  )
''');

    await db.execute('''
  CREATE TABLE IF NOT EXISTS daily_progress (
    date TEXT PRIMARY KEY,
    completed_pages INTEGER DEFAULT 0
  )
''');
  }

// New functions to manage suras
  Future<int> insertSura(Sura sura) async {
    final db = await database;
    return await db.insert(
      tableSuras,
      sura.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateSura(Sura sura) async {
    final db = await database;
    return await db.update(
      tableSuras,
      sura.toMap(),
      where: '$columnId = ?',
      whereArgs: [sura.id],
    );
  }

  Future<int> deleteSura(int id) async {
    final db = await database;
    return await db.delete(
      tableSuras,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateDailyProgress(
      DateTime date, List<int> completedSuras) async {
    final db = await database;
    await db.insert(
      tableProgress,
      {
        columnDate: _formatDate(date),
        columnCompleted: completedSuras.join(','),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> addSelectedSura(Sura sura) async {
    final db = await database;
    // Check if the sura already exists in the selected_suras table
    final List<Map<String, dynamic>> existingSuras = await db.query(
      'selected_suras',
      where: 'id = ?',
      whereArgs: [sura.id],
    );
 
    if (existingSuras.isEmpty) {
      await db.insert(
        'selected_suras',
        {
          'id': sura.id,
          'name': sura.name,
          'pages': sura.pages,
          'reviewed': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      print('Sura ${sura.name} already exists in selected_suras');
    }
  }

  Future<void> removeSelectedSura(int id) async {
    final db = await database;
    await db.delete(
      'selected_suras',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Sura>> getSelectedSuras() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('selected_suras');
    return maps
        .map((map) => Sura(
              id: map['id'],
              name: map['name'],
              pages: map['pages'],
              isCompleted: map['reviewed'] == 1,
            ))
        .toList();
  }

  Future<void> updateSuraReviewedStatus(int suraId, bool isCompleted) async {
    final db = await database;
    int result = await db.update(
      'selected_suras', // Update the table to selected_suras
      {'reviewed': isCompleted ? 1 : 0}, // Update the column to reviewed
      where: 'id = ?',
      whereArgs: [suraId],
    );

    if (result > 0) {
      print('Sura with ID $suraId updated successfully');
    } else {
      print('Failed to update sura with ID $suraId');
    }
  }

  Future<List<int>> getCompletedSuras(DateTime date) async {
    final db = await database;
    final result = await db.query(
      tableProgress,
      where: '$columnDate = ?',
      whereArgs: [_formatDate(date)],
    );

    if (result.isEmpty) return [];
    return (result.first[columnCompleted] as String)
        .split(',')
        .map(int.parse)
        .toList();
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }
}
