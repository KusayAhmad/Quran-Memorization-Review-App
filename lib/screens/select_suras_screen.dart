import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:quran_review_app/database/database_helper.dart';
import 'package:quran_review_app/models/sura_model.dart';
import 'package:quran_review_app/utils/sura_dialogs.dart';

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
    final selectedSuras = await _dbHelper.getSelectedSuras();
    setState(() {
      _selectedIds = selectedSuras.map((s) => s.id).toList();
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
      int aNum = int.tryParse(a.name) ?? 0;
      int bNum = int.tryParse(b.name) ?? 0;

      return _sortMode == 'asc' ? aNum.compareTo(bNum) : bNum.compareTo(aNum);
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
            onSelected: _sortSuras,
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
        return CheckboxListTile(
          title: Text(sura.name),
          subtitle: FutureBuilder<Map<String, dynamic>>(
            future: _dbHelper.getSuraStats(sura.id),
            builder: (context, snapshot) {
              final stats = snapshot.data ?? {};
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (stats['last_reviewed'] != null)
                    Text(
                        'آخر مراجعة: ${DateFormat('yyyy-MM-dd').format(stats['last_reviewed'])}'),
                  Text('عدد المراجعات: ${stats['total_times'] ?? 0}')
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
