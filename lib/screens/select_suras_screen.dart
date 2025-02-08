import 'package:flutter/material.dart';
import 'package:quran_review_app/database/database_helper.dart';
import 'package:quran_review_app/models/sura_model.dart';

class SelectSurasScreen extends StatefulWidget {
  const SelectSurasScreen({super.key});

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
    final suras = await db.query(DatabaseHelper.tableSuras);
    setState(() {
      _allSuras = suras
          .map((s) => Sura(
                id: s['id'] as int,
                name: s['name'] as String,
                pages: s['pages'] as int,
              ))
          .toList();

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
      _filteredSuras.sort((a, b) => b.name.compareTo(a.name));
    }
  }

   void _saveSelection() async {
    for (var sura in _allSuras) {
      if (_selectedIds.contains(sura.id)) {
        await _dbHelper.addSelectedSura(sura);
        print(
            'Selected suras saved: ${_selectedIds.map((id) => _allSuras.firstWhere((s) => s.id == id).name).toList()}');
      } else {
        await _dbHelper.removeSelectedSura(sura.id);
      }
    }
    Navigator.pop(context, true);
  }

  void _showAddSuraDialog(BuildContext context) {
    String suraName = '';
    int suraPages = 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Sura'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Sura Name'),
                onChanged: (value) {
                  suraName = value;
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Number of Pages'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  suraPages = int.tryParse(value) ?? 0;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                if (suraName.isNotEmpty && suraPages > 0) {
                  _addSura(suraName, suraPages);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addSura(String name, int pages) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT MAX(id) FROM ${DatabaseHelper.tableSuras}');
    final int highestId = (result.isNotEmpty && result[0]['MAX(id)'] != null)
        ? result[0]['MAX(id)'] as int
        : 0;
    final newId = highestId + 1;

    final newSura = Sura(id: newId, name: name, pages: pages);
    await _dbHelper.insertSura(newSura);
    _loadAllSuras();
  }

  void _showEditSuraDialog(BuildContext context, Sura sura) {
    String suraName = sura.name;
    int suraPages = sura.pages;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Sura'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Sura Name'),
                controller: TextEditingController(text: sura.name),
                onChanged: (value) {
                  suraName = value;
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Number of Pages'),
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
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Update'),
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
    Widget listWidget;
    listWidget = ListView.builder(
      itemCount: _filteredSuras.length,
      itemBuilder: (context, index) {
        final sura = _filteredSuras[index];
        return CheckboxListTile(
          title: Text(sura.name),
          subtitle: Text('${sura.pages} pages'),
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
              const PopupMenuItem<String>(
                value: 'edit',
                child: Text('Edit'),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          ),
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Suras for Review'),
        actions: [
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search Suras',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterSuras,
            ),
          ),
          Expanded(child: listWidget),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveSelection,
        child: const Icon(Icons.save),
      ),
    );
  }
}
