import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:quran_review_app/database/database_helper.dart';
import 'package:quran_review_app/models/sura_model.dart';
import 'package:quran_review_app/utils/sura_dialogs.dart';
import 'package:quran_review_app/models/sura_stats_model.dart';

class SelectSurasScreen extends StatefulWidget {
  final Function(Locale) setLocale;
  final bool isDarkMode;

  const SelectSurasScreen(
      {super.key, required this.setLocale, required this.isDarkMode});

  @override
  SelectSurasScreenState createState() => SelectSurasScreenState();
}

class SelectSurasScreenState extends State<SelectSurasScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Sura> _allSuras = [];
  List<Sura> _filteredSuras = [];
  List<int> _selectedIds = [];
  String _searchText = '';
  String _sortMode = 'asc';
  final Map<int, SuraStats> _suraStats = {};
// TODO: Add تطبيق آخر مقترحات شاتجب
  @override
  void initState() {
    super.initState();
    _loadSortMode();
    _loadAllSuras();
    _loadSelectedSuras();
  }

  Future<void> _loadSortMode() async {
    String? savedSortMode = await _dbHelper.getPreference('sortMode');
    setState(() {
      _sortMode = savedSortMode ?? 'asc';
    });
  }

  void _loadAllSuras() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps =
        await db.query(DatabaseHelper.tableSuras);
    setState(() {
      _allSuras = maps.map((map) => Sura.fromMap(map)).toList();
      _filteredSuras = List.from(_allSuras);
      _sortFilteredSuras();
    });
  }

  void _loadSelectedSuras() async {
    // 1) احصل على السور المختارة
    final selectedSuras = await _dbHelper.getSelectedSuras();

    // 2) تفريغ الخريطة السابقة (اختياري)
    _suraStats.clear();

    // 3) لكل سورة، اجلب معلومات الإحصائيات من sura_stats
    for (var sura in selectedSuras) {
      final stats = await _dbHelper.getSuraStats(sura.id);
      if (stats != null) {
        _suraStats[sura.id] = stats;
      }
    }

    // 4) حدث واجهة المستخدم
    setState(() {
      // احفظ قائمة المعرفات
      _selectedIds = selectedSuras.map((s) => s.id).toList();
      // إذا كنت تستعمل _allSuras يمكنك تصفيتها لجلب ما هو مختار فقط:
      _filteredSuras = _allSuras.where((s) => _selectedIds.contains(s.id)).toList();
      _sortFilteredSuras(); // إعادة فرز القائمة حسب الوضع المختار
    });
  }



  void _filterSuras(String searchText) {
    setState(() {
      _searchText = searchText;
      _filteredSuras = _allSuras.where((sura) {
        return sura.name.toLowerCase().contains(_searchText.toLowerCase());
      }).toList();
      _sortFilteredSuras();
    });
  }

  void _sortSuras(String sortMode) {
    setState(() {
      _sortMode = sortMode;
      _saveSortMode(sortMode);
      _sortFilteredSuras();
    });
  }

  Future<void> _saveSortMode(String sortMode) async {
    await _dbHelper.setPreference('sortMode', sortMode);
  }

  void _sortFilteredSuras() {
    _filteredSuras.sort((a, b) {
      if (_sortMode == 'last_reviewed') {
        return _suraStats[a.id]?.lastReviewedDate.compareTo(
                _suraStats[b.id]?.lastReviewedDate ?? DateTime(2000)) ??
            0;
      } else {
        int aNum = int.tryParse(a.name) ?? 0;
        int bNum = int.tryParse(b.name) ?? 0;
        return _sortMode == 'asc' ? aNum.compareTo(bNum) : bNum.compareTo(aNum);
      }
    });
  }

  void _saveSelection() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context)!.select_at_least_one_sura)),
      );
      return;
    }

    await _dbHelper.updateSelectedSuras(_selectedIds);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor =
        widget.isDarkMode ? Colors.grey.shade900 : Colors.pink.shade300;
    final Color backgroundColor =
        widget.isDarkMode ? Colors.black : Colors.pink.shade50;
    final Color textColor = widget.isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.selectSuras,
            style: TextStyle(color: textColor)),
        backgroundColor: primaryColor,
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              setState(() {
                _sortMode = value;
                _sortFilteredSuras();
              });
            },
            icon: const Icon(Icons.sort),
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'asc',
                child: Text(AppLocalizations.of(context)!.sortAZ),
              ),
              PopupMenuItem<String>(
                value: 'desc',
                child: Text(AppLocalizations.of(context)!.sortZA),
              ),
              PopupMenuItem<String>(
                value: 'last_reviewed',
                child: Text(AppLocalizations.of(context)!.sortByLastReviewed),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showAddSuraDialog(
                context,
                _loadAllSuras,
                AppLocalizations.of(context)!,
              );
            },
          ),
        ],
      ),
      body: Container(
        color: backgroundColor,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.searchSuras,
                  prefixIcon: Icon(Icons.search, color: textColor),
                  labelStyle: TextStyle(color: textColor),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: textColor)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: textColor)),
                ),
                style: TextStyle(color: textColor),
                onChanged: _filterSuras,
              ),
            ),
            Expanded(child: _buildListView()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveSelection,
        backgroundColor: primaryColor,
        child: Text(AppLocalizations.of(context)!.save),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: _filteredSuras.length,
      itemBuilder: (context, index) {
        final sura = _filteredSuras[index];
        final stats = _suraStats[sura.id];  // سحب الإحصائيات من الخريطة

        return CheckboxListTile(
          title: Text(sura.name),
          subtitle: Builder(
            builder: (context) {
              if (stats == null) {
                return const Text('لا توجد بيانات مراجعة.');
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('آخر مراجعة: ${stats.lastReviewedDate.toLocal().toString().split(' ').first}'),
                  Text('عدد المراجعات: ${stats.totalReviewedTimes}'),
                ],
              );
            },
          ),
          value: _selectedIds.contains(sura.id),
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _selectedIds.add(sura.id);
              } else {
                _selectedIds.remove(sura.id);
              }
            });
          },
          secondary: PopupMenuButton<String>(
            onSelected: (String value) {
              if (value == 'edit') {
                showEditSuraDialog(
                  context,
                  sura,
                  (updatedSura) async {
                    await _dbHelper.updateSura(updatedSura);
                    _loadAllSuras();
                  },
                  AppLocalizations.of(context)!,
                );
              } else if (value == 'delete') {
                _dbHelper.deleteSura(sura.id);
                setState(() {
                  _filteredSuras.removeWhere((s) => s.id == sura.id);
                });
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'edit',
                child: Text(
                  AppLocalizations.of(context)!.edit,
                  style: TextStyle(color: Colors.black),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  AppLocalizations.of(context)!.delete,
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
