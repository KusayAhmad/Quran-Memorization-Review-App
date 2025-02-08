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

  List<Sura> _suras = [];
  bool _isLoading = true;
  double _progress = 0.0;

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

  Widget _buildListView() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Memorized'),
        actions: [
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
