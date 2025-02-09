import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../database/database_helper.dart';
import '../models/sura_model.dart';
import 'select_suras_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(Locale) setLocale;

  const HomeScreen({super.key, required this.setLocale});

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

  Future<void> _loadData() async {
    try {
      final suras = await _dbHelper.getSelectedSuras();
      setState(() {
        _suras = suras;
        _isLoading = false;
      });
      _calculateProgress();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    }
  }

  void _calculateProgress() {
    final total = _suras.fold(0, (sum, s) => sum + s.pages);
    final completed = _suras.where((s) => s.isCompleted).fold(0, (sum, s) => sum + s.pages);
    setState(() {
      _progress = total > 0 ? completed / total : 0.0;
    });
  }

  Future<void> _updateProgress(Sura sura) async {
    try {
      await _dbHelper.updateSuraReviewedStatus(sura.id, sura.isCompleted);
      _calculateProgress();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update progress: $e')),
      );
    }
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: _suras.length,
      itemBuilder: (context, index) {
        final sura = _suras[index];
        final percentage = (_suras.isNotEmpty && _suras[0].pages > 0)
            ? (sura.pages / _suras.fold(0, (sum, s) => sum + s.pages)) * 100
            : 0;

        return CheckboxListTile(
          title: Text('${sura.name} (${percentage.toStringAsFixed(1)}%)'),
          subtitle: Text('${sura.pages} ${AppLocalizations.of(context)!.pages}'),
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

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.congratulations),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18.0,
        ),
        content: Text(
          AppLocalizations.of(context)!.reviewCompleted,
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearReviewedSuras();
            },
            child: Text(AppLocalizations.of(context)!.alhamdulillah),
            style: TextButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 164, 190, 151),
                foregroundColor: Color.fromARGB(255, 0, 0, 0),
                textStyle: const TextStyle(
                    fontSize: 18.0, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _clearReviewedSuras() async {
    try {
      final db = await _dbHelper.database;
      await db.delete('selected_suras');
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clear data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.homeScreenTitle),
        backgroundColor: const Color.fromARGB(255, 164, 190, 151),
        actions: [
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            onSelected: (Locale locale) async {
              await DatabaseHelper().setSelectedLanguage(locale.languageCode);
              widget.setLocale(locale);
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: Locale('en'),
                child: Text(AppLocalizations.of(context)!.languageEnglish),
              ),
              PopupMenuItem(
                value: Locale('ar'),
                child: Text(AppLocalizations.of(context)!.languageArabic),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: AppLocalizations.of(context)!.edit,
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SelectSurasScreen(setLocale: widget.setLocale),
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
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(child: _buildListView()),
                  LinearPercentIndicator(
                    lineHeight: 30.0,
                    animation: true,
                    percent: _progress,
                    backgroundColor: Colors.grey[300],
                    progressColor: const Color.fromARGB(255, 164, 190, 151),
                    center: Text(
                      '${(_progress * 100).toStringAsFixed(1)}%',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}