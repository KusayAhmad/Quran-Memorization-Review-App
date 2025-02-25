import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:quran_review_app/database/database_helper.dart';
import 'package:quran_review_app/models/sura_model.dart';
import 'package:quran_review_app/screens/select_suras_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(Locale) setLocale;
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  const HomeScreen(
      {super.key,
      required this.setLocale,
      required this.isDarkMode,
      required this.toggleTheme});
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update progress: $e')),
        );
      }
    }
  }

  void _calculateProgress() {
    final total = _suras.fold(0.0, (sum, s) => sum + s.pages);
    final completed =
        _suras.where((s) => s.isCompleted).fold(0.0, (sum, s) => sum + s.pages);
    setState(() {
      _progress = total > 0.0 ? completed / total : 0.0;
    });
  }

  String _getFormattedReviewedPages() {
    double reviewedPages =
        _suras.where((s) => s.isCompleted).fold(0.0, (sum, s) => sum + s.pages);
    return reviewedPages.toStringAsFixed(2);
  }

  void _checkCompletion(Color primaryColor) {
    if (_progress >= 1.0) {
      _showCompletionDialog(primaryColor, _getFormattedReviewedPages());

      // ✅ تحديث الإحصائيات عند الانتهاء من جميع السور
      _dbHelper.updateSuraStatsForAll(_suras.map((s) => s.id).toList());
    }
  }

  Future<void> _updateProgress(Sura sura) async {
    try {
      await _dbHelper.updateSuraReviewedStatus(sura.id, sura.isCompleted);
      _calculateProgress();

      // تحديث الإحصائيات فقط عند اكتمال جميع السور
      // if (_progress >= 1.0) {
      //   await _dbHelper.updateSuraStatsForAll(_suras.map((s) => s.id).toList());
      // }
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
            ? (sura.pages / _suras.fold(0.0, (sum, s) => sum + s.pages)) * 100
            : 0.0;

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
              _checkCompletion(primaryColor);
            },
            background: Container(color: Colors.redAccent),
            child: CheckboxListTile(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              checkColor: widget.isDarkMode ? Colors.black : Colors.white,
              tileColor:
                  widget.isDarkMode ? Colors.grey.shade800 : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              title: Text(
                '${sura.name} ',
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                  fontSize: 18.0,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${sura.pages} ${AppLocalizations.of(context)!.pages} (${percentage.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          widget.isDarkMode ? Colors.white70 : Colors.black87,
                      fontSize: 14.0,
                    ),
                  ),
                ],
              ),
              value: sura.isCompleted,
              onChanged: (value) async {
                setState(() => sura.isCompleted = value ?? false);
                await _updateProgress(sura);

                _checkCompletion(primaryColor);
              },
            ),
          ),
        );
      },
    );
  }

  void _showCompletionDialog(Color primaryColor, formattedPages) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            widget.isDarkMode ? Colors.grey.shade900 : Colors.white,
        title: Text(
          AppLocalizations.of(context)!.congratulations,
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black,
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!
              .reviewCompletedWithPages(formattedPages),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black,
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
      final db = await _dbHelper.database;
      await db.delete('selected_suras');
      _loadData(); // إعادة تحميل البيانات لتحديث الواجهة
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reset suras: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor =
        widget.isDarkMode ? Colors.grey.shade900 : Colors.pink.shade300;
    final Color secondaryColor =
        widget.isDarkMode ? Colors.grey.shade800 : Colors.pink.shade200;
    final Color backgroundColor =
        widget.isDarkMode ? Colors.black : Colors.pink.shade50;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.homeScreenTitle,
          style:
              TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
        ),
        backgroundColor: primaryColor,
        actions: [
          PopupMenuButton<Locale>(
            icon: Icon(
              Icons.language,
              size: 24.0,
              color: widget.isDarkMode ? Colors.white : Colors.black,
            ),
            position: PopupMenuPosition.under,
            onSelected: (Locale locale) async {
              await DatabaseHelper().setSelectedLanguage(locale.languageCode);
              widget.setLocale(locale);
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: Locale('en'),
                child: Text(
                  AppLocalizations.of(context)!.languageEnglish,
                  style: TextStyle(color: Colors.black),
                ),
              ),
              PopupMenuItem(
                value: Locale('ar'),
                child: Text(
                  AppLocalizations.of(context)!.languageArabic,
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.wb_sunny : Icons.nights_stay,
              size: 24.0,
              color: widget.isDarkMode ? Colors.white : Colors.black,
            ),
            tooltip: widget.isDarkMode
                ? 'التبديل إلى الوضع النهاري'
                : 'التبديل إلى الوضع الليلي',
            onPressed: () {
              widget.toggleTheme();
            },
          ),
          IconButton(
            icon: Icon(Icons.edit,
                size: 24.0,
                color: widget.isDarkMode ? Colors.white : Colors.black),
            tooltip: AppLocalizations.of(context)!.edit,
            onPressed: () async {
              final result = await Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => SelectSurasScreen(
                      setLocale: widget.setLocale,
                      isDarkMode: widget.isDarkMode),
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
                  Text(
                    'الصفحات المراجعة: ${_getFormattedReviewedPages()}',
                    style: TextStyle(
                      fontSize: 18,
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  LinearPercentIndicator(
                    lineHeight: 30.0,
                    animation: true,
                    animateFromLastPercent: true,
                    animationDuration: 500,
                    restartAnimation: false,
                    barRadius: const Radius.circular(10),
                    percent: _progress,
                    backgroundColor: widget.isDarkMode
                        ? Color.fromARGB(255, 191, 191, 191)
                        : Colors.grey[300],
                    linearGradient: LinearGradient(
                      colors: [primaryColor, secondaryColor],
                    ),
                    center: Text(
                      '${(_progress * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.white : Colors.black,
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
