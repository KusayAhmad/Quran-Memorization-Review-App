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
  late Future<List<Sura>> _surasFuture;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  double _progress = 0.0;
  bool _completionDialogShown = false; // Add this variable

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    // Assign the value immediately without waiting for asynchronous execution here.
    _surasFuture = _getSurasWithProgress();
    _calculateProgress();
  }

  Future<List<Sura>> _getSurasWithProgress() async {
    final suras = await _dbHelper.getSelectedSuras();
    print('Number of retrieved suras: ${suras.length}');
    return suras;
  }

  void _calculateProgress() async {
    final suras = await _surasFuture;
    final total = suras.fold(0, (sum, s) => sum + s.pages);
    final completed =
        suras.where((s) => s.isCompleted).fold(0, (sum, s) => sum + s.pages);

    setState(() {
      _progress = total > 0 ? completed / total : 0.0;
    });

    // Check if progress is 100% and show the dialog only if it hasn't been shown
    if (_progress >= 1.0 && !_completionDialogShown) {
      _showCompletionDialog();
      _completionDialogShown = true; // Set to true after showing the dialog
    } else if (_progress < 1.0) {
      _completionDialogShown = false; // Reset if progress is less than 100%
    }
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
              _clearReviewedSuras(); // Call the function to clear reviewed suras
            },
            child: const Text('Alhamdullah ♥'),
          ),
        ],
      ),
    );
  }

  void _clearReviewedSuras() async {
    final db = await _dbHelper.database;
    await db.delete('selected_suras'); // Clear the table of selected suras
    setState(() {
      _surasFuture = _getSurasWithProgress(); // Refresh the list
    });
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
              // Navigate to the selection page
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SelectSurasScreen()),
              );
              // If the return result is true, it means there are changes
              if (result == true) {
                setState(() {
                  _surasFuture = _getSurasWithProgress();
                });
                _calculateProgress();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Sura>>(
              future: _surasFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                      child: Text('Error occurred: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data == null) {
                  // If no data is available, display an appropriate message
                  return const Center(child: Text('No data available'));
                }

                // When data is confirmed to be available, use snapshot.data!
                final suras = snapshot.data!;
                return ListView.builder(
                  itemCount: suras.length,
                  itemBuilder: (context, index) {
                    final sura = suras[index];
                    return CheckboxListTile(
                      title: Text(sura.name),
                      subtitle: Text('${sura.pages} pages'),
                      value: sura.isCompleted,
                      onChanged: (value) async {
                        setState(() => sura.isCompleted = value ?? false);
                        await _updateProgress(sura);
                        if (_progress >= 1.0) _showCompletionDialog();
                      },
                    );
                  },
                );
              },
            ),
          ),
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
