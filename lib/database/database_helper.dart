import 'package:path/path.dart';
import 'package:quran_review_app/models/sura_model.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  DatabaseHelper._privateConstructor();

  static final _databaseName = "QuranReview.db";
  static final _databaseVersion = 5;

  static final tableSuras = 'suras';
  static final columnId = 'id';
  static final columnName = 'name';
  static final columnPages = 'pages';

  static final tableProgress = 'daily_progress';
  static final columnDate = 'date';
  static final columnCompleted = 'completed_suras';

  static final tablePreferences = 'preferences';
  static final columnPreferenceName = 'name';
  static final columnPreferenceValue = 'value';

  static Database? _database;
  static final tableStats = 'sura_stats';

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
      $columnPages REAL NOT NULL,
      reviewed BOOLEAN DEFAULT 0,
      last_reviewed_date TEXT,
      total_reviewed_times INTEGER DEFAULT 0
    )
  ''');

    await db.execute('''
      CREATE TABLE $tableProgress (
        $columnDate TEXT PRIMARY KEY,
        $columnCompleted TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE selected_suras (
        id INTEGER,
        name TEXT NOT NULL,
        pages REAL NOT NULL,
        reviewed BOOLEAN DEFAULT 0,
        last_reviewed_date TEXT,
        total_reviewed_times INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE $tablePreferences (
        $columnPreferenceName TEXT PRIMARY KEY,
        $columnPreferenceValue TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableStats (
        sura_id INTEGER PRIMARY KEY,
        last_reviewed_date TEXT,
        total_reviewed_times INTEGER DEFAULT 0,
        FOREIGN KEY (sura_id) REFERENCES $tableSuras(id)
      )
    ''');
  }

  Future<int> insertSura({required String name, required double pages}) async {
    final db = await database;
    final int newId = await generateNewSuraId();
    final Sura newSura = Sura(id: newId, name: name, pages: pages);
    return await db.insert(
      tableSuras,
      newSura.toMap(),
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
          'reviewed': sura.isCompleted ? 1 : 0,
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
    await db.update(
      'selected_suras',
      {'reviewed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [suraId],
    );
  }

  Future<Map<String, dynamic>> getSuraStats(int suraId) async {
    final db = await database;
    final stats = await db.query(
      tableStats,
      where: 'sura_id = ?',
      whereArgs: [suraId],
    );

    return stats.isNotEmpty
        ? {
            'last_reviewed':
                DateTime.parse(stats[0]['last_reviewed_date'] as String),
            'total_times': stats[0]['total_reviewed_times'] as int
          }
        : {'last_reviewed': null, 'total_times': 0};
  }

  Future<void> updateSuraStats(int suraId) async {
    final db = await database;
    final currentDate = _formatDate(DateTime.now());

    await db.rawInsert('''
    INSERT INTO $tableStats (
      sura_id, 
      last_reviewed_date, 
      total_reviewed_times
    ) 
    VALUES (?, ?, 1)
    ON CONFLICT(sura_id) 
    DO UPDATE SET
      last_reviewed_date = excluded.last_reviewed_date,
      total_reviewed_times = total_reviewed_times + 1
  ''', [suraId, currentDate]);
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
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<String?> getPreference(String name) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      tablePreferences,
      where: '$columnPreferenceName = ?',
      whereArgs: [name],
    );
    if (result.isNotEmpty) {
      return result.first[columnPreferenceValue] as String?;
    }
    return null;
  }

  Future<void> setPreference(String name, String value) async {
    final db = await database;
    await db.insert(
      tablePreferences,
      {
        columnPreferenceName: name,
        columnPreferenceValue: value,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setSelectedLanguage(String languageCode) async {
    await setPreference('selectedLanguage', languageCode);
  }

  Future<String?> getSelectedLanguage() async {
    return await getPreference('selectedLanguage');
  }

  Future<int> generateNewSuraId() async {
    final db = await database;
    final result = await db.rawQuery('SELECT MAX(id) FROM $tableSuras');
    return (result.isNotEmpty && result[0]['MAX(id)'] != null)
        ? (result[0]['MAX(id)'] as int) + 1
        : 1;
  }

  Future<List<Sura>> getAllSuras() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableSuras);
    return maps.map((map) => Sura.fromMap(map)).toList();
  }

  Future<void> updateSelectedSuras(List<int> selectedIds) async {
    final db = await database;
    await db.delete('selected_suras');
    for (int id in selectedIds) {
      final sura =
          await db.query(tableSuras, where: '$columnId = ?', whereArgs: [id]);
      if (sura.isNotEmpty) {
        await db.insert('selected_suras', {
          'id': id,
          'name': sura[0][columnName],
          'pages': sura[0][columnPages],
          'reviewed': 0,
          'last_reviewed_date': null,
          'total_reviewed_times': 0,
        });
      }
    }
  }

  Future<void> updateSuraStatsForAll(List<int> suraIds) async {
    final db = await database;
    final currentDate = _formatDate(DateTime.now());

    for (int suraId in suraIds) {
      await db.rawInsert('''
      INSERT INTO $tableStats (
        sura_id, 
        last_reviewed_date, 
        total_reviewed_times
      ) 
      VALUES (?, ?, 1)
      ON CONFLICT(sura_id) 
      DO UPDATE SET
        last_reviewed_date = excluded.last_reviewed_date,
        total_reviewed_times = total_reviewed_times + 1
    ''', [suraId, currentDate]);
    }
  }
}
