import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../database/database_helper.dart';
import '../models/sura_model.dart';
import 'select_suras_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Sura> _suras = []; // قائمة السور المحملة من قاعدة البيانات
  bool _isLoading = true;
  double _progress = 0.0;
  bool _completionDialogShown = false;

  // متغيرات ترتيب السور
  bool _isManualOrder = false; // هل الترتيب يدوي (سحب وإفلات)
  bool _alphabeticalAscending = true; // الترتيب الأبجدي تصاعدياً (افتراضي)

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    List<Sura> suras = await _getSurasWithProgress();
    setState(() {
      _suras = suras;
      _isLoading = false;
    });
    _calculateProgress();
  }

  Future<List<Sura>> _getSurasWithProgress() async {
    final suras = await _dbHelper.getSelectedSuras();
    print('Number of retrieved suras: ${suras.length}');
    return suras;
  }

  // حساب النسبة المئوية للمراجعة بناءً على عدد الصفحات المكتملة
  void _calculateProgress() {
    final total = _suras.fold(0, (sum, s) => sum + s.pages);
    final completed =
        _suras.where((s) => s.isCompleted).fold(0, (sum, s) => sum + s.pages);

    setState(() {
      _progress = total > 0 ? completed / total : 0.0;
    });
  }

  Future<void> _updateProgress(Sura sura) async {
    await _dbHelper.updateSuraReviewedStatus(sura.id, sura.isCompleted);
    _calculateProgress();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Congratulations!'),
        content: const Text(
          'You have completed your review for today (＾ᗜ＾)\n'
          'May Allah accept and grant steadfastness',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearReviewedSuras();
            },
            child: const Text('Alhamdullah ♥'),
          ),
        ],
      ),
    );
  }

  void _clearReviewedSuras() async {
    final db = await _dbHelper.database;
    await db.delete('selected_suras');
    _loadData();
  }

  void _sortSuras(String sortOption) {
    setState(() {
      if (sortOption == 'asc') {
        _isManualOrder = false;
        _alphabeticalAscending = true;
        _suras.sort((a, b) => a.name.compareTo(b.name));
      } else if (sortOption == 'desc') {
        _isManualOrder = false;
        _alphabeticalAscending = false;
        _suras.sort((a, b) => b.name.compareTo(a.name));
      } else if (sortOption == 'manual') {
        _isManualOrder = true;
      }
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Sura sura = _suras.removeAt(oldIndex);
      _suras.insert(newIndex, sura);
    });
  }

  Widget _buildListView() {
    if (_isManualOrder) {
      return ReorderableListView(
        onReorder: _onReorder,
        children: _suras.map((sura) {
          final total = _suras.fold(0, (sum, s) => sum + s.pages);
          final percentage = total > 0 ? (sura.pages / total) * 100 : 0;
          return CheckboxListTile(
            key: ValueKey(sura.id),
            title: Text('${sura.name} (${percentage.toStringAsFixed(1)}%)'),
            subtitle: Text('${sura.pages} pages'),
            value: sura.isCompleted,
            onChanged: (value) async {
              setState(() {
                sura.isCompleted = value ?? false;
              });
              await _updateProgress(sura);
              if (_progress >= 1.0) _showCompletionDialog();
            },
          );
        }).toList(),
      );
    } else {
      return ListView.builder(
        itemCount: _suras.length,
        itemBuilder: (context, index) {
          final sura = _suras[index];
          final total = _suras.fold(0, (sum, s) => sum + s.pages);
          final percentage = total > 0 ? (sura.pages / total) * 100 : 0;
          return CheckboxListTile(
            key: ValueKey(sura.id),
            title: Text('${sura.name} (${percentage.toStringAsFixed(1)}%)'),
            subtitle: Text('${sura.pages} pages'),
            value: sura.isCompleted,
            onChanged: (value) async {
              setState(() {
                sura.isCompleted = value ?? false;
              });
              await _updateProgress(sura);
              if (_progress >= 1.0) _showCompletionDialog();
            },
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Memorized'),
        actions: [
          // زر القائمة المنسدلة لاختيار نوع الترتيب
          PopupMenuButton<String>(
            onSelected: _sortSuras,
            icon: const Icon(Icons.sort),
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'asc',
                child: Text('Sort A-Z'),
              ),
              const PopupMenuItem<String>(
                value: 'desc',
                child: Text('Sort Z-A'),
              ),
              const PopupMenuItem<String>(
                value: 'manual',
                child: Text('Manual Reorder'),
              ),
            ],
          ),
          // زر الانتقال إلى شاشة اختيار السور
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SelectSurasScreen(),
                ),
              );
              if (result == true) {
                _loadData();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: _buildListView()),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: LinearPercentIndicator(
                    lineHeight: 20.0,
                    percent: _progress,
                    backgroundColor: Colors.grey,
                    progressColor: Colors.green,
                    center: Text('${(_progress * 100).toStringAsFixed(1)}%'),
                  ),
                ),
              ],
            ),
    );
  }
}
