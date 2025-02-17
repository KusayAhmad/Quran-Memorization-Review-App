import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../database/database_helper.dart';
import '../models/sura_model.dart';
import 'select_suras_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final Function(Locale) setLocale;
  final SharedPreferences prefs;

  const HomeScreen({super.key, required this.setLocale, required this.prefs});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Sura> _suras = [];
  bool _isLoading = true;
  double _progress = 0.0;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.prefs.getBool('isDarkMode') ?? false;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update progress: $e')),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update progress: $e')),
        );
      }
    }
  }

  Widget _buildListView(Color primaryColor) {
    return ListView.builder(
      itemCount: _suras.length,
      itemBuilder: (context, index) {
        final sura = _suras[index];
        final percentage = (_suras.isNotEmpty && _suras[0].pages > 0)
            ? (sura.pages / _suras.fold(0, (sum, s) => sum + s.pages)) * 100
            : 0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Dismissible(
            key: Key(sura.id.toString()),
            direction: DismissDirection.horizontal,
            onDismissed: (direction) async {
              final removedSura = _suras[index];
              await _dbHelper.removeSelectedSura(removedSura.id);
              setState(() {
                _suras.removeAt(index);
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '${removedSura.name} ${AppLocalizations.of(context)!.suraRemoved}'),
                    action: SnackBarAction(
                      label: AppLocalizations.of(context)!.undo,
                      onPressed: () async {
                        await _dbHelper.addSelectedSura(removedSura);
                        setState(() {
                          _suras.insert(index, removedSura);
                        });
                        _calculateProgress();
                      },
                    ),
                  ),
                );
              }
              await _updateProgress(removedSura);
              if (_progress >= 1.0) _showCompletionDialog(primaryColor);
            },
            background: Container(color: Colors.redAccent),
            child: CheckboxListTile(
              contentPadding:
              const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              tileColor: _isDarkMode ? Colors.grey.shade800 : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              title: Text(
                '${sura.name} (${percentage.toStringAsFixed(1)}%)',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : Colors.white70,
                  fontSize: 18.0,
                ),
              ),
              subtitle: Text(
                '${sura.pages} ${AppLocalizations.of(context)!.pages}',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white70 : Colors.black87,
                  fontSize: 14.0,
                ),
              ),
              value: sura.isCompleted,
              onChanged: (value) async {
                setState(() {
                  sura.isCompleted = value ?? false;
                });
                await _updateProgress(sura);
                if (_progress >= 1.0) _showCompletionDialog(primaryColor);
              },
            ),
          ),
        );
      },
    );
  }

  void _showCompletionDialog(Color primaryColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? Colors.grey.shade900 : Colors.white,
        title: Text(
          AppLocalizations.of(context)!.congratulations,
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black,
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.reviewCompleted,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black,
            fontSize: 18.0,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearReviewedSuras();
            },
            style: TextButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.black,
              textStyle: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Text(AppLocalizations.of(context)!.alhamdulillah),
          ),
        ],
      ),
    );
  }

  Future<void> _clearReviewedSuras() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_suras');
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor =
    _isDarkMode ? Colors.grey.shade900 : Colors.pink.shade300;
    final Color secondaryColor =
    _isDarkMode ? Colors.grey.shade800 : Colors.pink.shade200;
    final Color backgroundColor =
    _isDarkMode ? Colors.black : Colors.pink.shade50;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.homeScreenTitle,
          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
        ),
        backgroundColor: primaryColor,
        actions: [
          PopupMenuButton<Locale>(
            icon: Icon(
              Icons.language,
              size: 24.0,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
            onSelected: (Locale locale) async {
              await DatabaseHelper().setSelectedLanguage(locale.languageCode);
              widget.setLocale(locale);
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: Locale('en'),
                child: Text(
                  AppLocalizations.of(context)!.languageEnglish,
                  style: TextStyle(color: _isDarkMode ? Colors.black : Colors.black),
                ),
              ),
              PopupMenuItem(
                value: Locale('ar'),
                child: Text(
                  AppLocalizations.of(context)!.languageArabic,
                  style: TextStyle(color: _isDarkMode ? Colors.black : Colors.black),
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              _isDarkMode ? Icons.wb_sunny : Icons.nights_stay,
              size: 24.0,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
            tooltip:
            _isDarkMode ? 'تبديل الوضع النهاري' : 'تبديل الوضع الليلي',
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.edit,
                size: 24.0, color: _isDarkMode ? Colors.white : Colors.black),
            tooltip: AppLocalizations.of(context)!.edit,
            onPressed: () async {
              final result = await Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) =>
                      SelectSurasScreen(setLocale: widget.setLocale, prefs: widget.prefs),
                  transitionDuration: const Duration(milliseconds: 300),
                  transitionsBuilder: (_, anim, __, child) =>
                      FadeTransition(opacity: anim, child: child),
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
            LinearPercentIndicator(
              lineHeight: 30.0,
              animation: true,
              percent: _progress,
              backgroundColor: Colors.grey[300],
              linearGradient: LinearGradient(
                colors: [primaryColor, secondaryColor],
              ),
              center: Text(
                '${(_progress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Expanded(child: _buildListView(primaryColor)),
          ],
        ),
      ),
    );
  }
}
