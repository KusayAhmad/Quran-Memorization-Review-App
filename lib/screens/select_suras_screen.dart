import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../database/database_helper.dart';
import '../models/sura_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelectSurasScreen extends StatefulWidget {
  final Function(Locale) setLocale;
  final SharedPreferences prefs;
  final bool isDarkMode;

  const SelectSurasScreen({super.key, required this.setLocale, required this.prefs, required this.isDarkMode});

  @override
  SelectSurasScreenState createState() => SelectSurasScreenState();
}

class SelectSurasScreenState extends State<SelectSurasScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Sura> _allSuras = [];
  List<Sura> _filteredSuras = [];
  List<int> _selectedIds = [];
  String _searchText = '';
  String _sortMode = 'asc';
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _loadSortMode();
    _loadAllSuras();
    _loadSelectedSuras();
  }

  Future<void> _loadSortMode() async {
    String? savedSortMode = widget.prefs.getString('sortMode');
    setState(() {
      _sortMode = savedSortMode ?? 'asc';
    });
  }

  void _loadAllSuras() async {
    final allSuras = await _dbHelper.getAllSuras();
    setState(() {
      _allSuras = allSuras;
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
    if (_sortMode == 'asc') {
      _filteredSuras.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sortMode == 'desc') {
      _filteredSuras.sort((a, b) => b.name.compareTo(b.name));
    }
  }

  void _saveSelection() async {
    for (var sura in _allSuras) {
      if (_selectedIds.contains(sura.id)) {
        await _dbHelper.addSelectedSura(sura);
      } else {
        await _dbHelper.removeSelectedSura(sura.id);
      }
    }
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  void _showAddSuraDialog(BuildContext context) {
    String suraName = '';
    int suraPages = 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.addNewSura),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.suraName),
                onChanged: (value) {
                  suraName = value;
                },
              ),
              TextField(
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.numberOfPages),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  suraPages = int.tryParse(value) ?? 0;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () async {
                if (suraName.isNotEmpty && suraPages > 0) {
                  await _addSura(suraName, suraPages);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        backgroundColor:
                        const Color.fromARGB(255, 226, 120, 112),
                        content: Text(
                            AppLocalizations.of(context)!.invalidInput,
                            style: TextStyle(
                                color: const Color.fromARGB(255, 0, 0, 0),
                                fontWeight: FontWeight.bold))),
                  );
                }
              },
              child: Text(AppLocalizations.of(context)!.add),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addSura(String name, int pages) async {
    final allSuras = await _dbHelper.getAllSuras();
    final int highestId = allSuras.isNotEmpty
        ? allSuras.map((s) => s.id).reduce((a, b) => a > b ? a : b)
        : 0;
    final newId = highestId + 1;

    final newSura = Sura(id: newId, name: name, pages: pages);
    await _dbHelper.addSura(newSura);
    _loadAllSuras();
  }

  void _showEditSuraDialog(BuildContext context, Sura sura) {
    String suraName = sura.name;
    int suraPages = sura.pages;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.edit),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.suraName),
                controller: TextEditingController(text: sura.name),
                onChanged: (value) {
                  suraName = value;
                },
              ),
              TextField(
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.numberOfPages),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: sura.pages.toString()),
                onChanged: (value) {
                  suraPages = int.tryParse(value) ?? 0;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.update),
              onPressed: () {
                if (suraName.isNotEmpty && suraPages > 0) {
                  _updateSura(
                      Sura(id: sura.id, name: suraName, pages: suraPages));
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateSura(Sura sura) async {
    await _dbHelper.updateSura(sura);
    _loadAllSuras();
  }

  Future<void> _deleteSura(Sura sura) async {
    await _dbHelper.deleteSura(sura.id);
    _loadAllSuras();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = _isDarkMode ? Colors.grey.shade900 : Colors.pink.shade300;
    final Color backgroundColor = _isDarkMode ? Colors.black : Colors.pink.shade50;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.selectSuras),
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
              _showAddSuraDialog(context);
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
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: _filterSuras,
              ),
            ),
            Expanded(child: _buildListView()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveSelection,
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
          tileColor: _isDarkMode ? Colors.grey.shade800 : Colors.white,
          title: Text(sura.name),
          subtitle: Text('${sura.pages} ${AppLocalizations.of(context)!.pages}'),
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
                _showEditSuraDialog(context, sura);
              } else if (value == 'delete') {
                _deleteSura(sura);
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'edit',
                child: Text(AppLocalizations.of(context)!.edit),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Text(AppLocalizations.of(context)!.delete),
              ),
            ],
          ),
        );
      },
    );
  }
}
