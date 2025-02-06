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
  List<int> _selectedIds = [];

  @override
  void initState() {
    super.initState();
    _loadAllSuras();
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
    });
  }

  void _saveSelection() async {
    for (var sura in _allSuras) {
      if (_selectedIds.contains(sura.id)) {
        await _dbHelper.addSelectedSura(sura);
        print(
            'Selected suras saved: ${_selectedIds.map((id) => _allSuras.firstWhere((sura) => sura.id == id).name).toList()}');
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
  // Get the highest existing id
  final db = await _dbHelper.database;
  final List<Map<String, dynamic>> result = await db.rawQuery('SELECT MAX(id) FROM ${DatabaseHelper.tableSuras}');
  final int highestId = (result.isNotEmpty && result[0]['MAX(id)'] != null) ? result[0]['MAX(id)'] as int : 0;

  // Increment the highest id to get a new unique id
  final newId = highestId + 1;

  final newSura = Sura(id: newId, name: name, pages: pages);
  await _dbHelper.insertSura(newSura);
  _loadAllSuras(); // Reload suras to update the list
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
                onChanged: (value) {
                  suraName = value;
                },
                controller: TextEditingController(text: sura.name),
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Number of Pages'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  suraPages = int.tryParse(value) ?? 0;
                },
                controller: TextEditingController(text: sura.pages.toString()),
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
    _loadAllSuras(); // Reload suras to update the list
  }

  Future<void> _deleteSura(Sura sura) async {
    await _dbHelper.deleteSura(sura.id);
    _loadAllSuras(); // Reload suras to update the list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Suras for Review'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddSuraDialog(context);
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _allSuras.length,
        itemBuilder: (context, index) {
          final sura = _allSuras[index];
          return CheckboxListTile(
            title: Text(sura.name),
            subtitle: Text('${sura.pages} pages'),
            value: _selectedIds.contains(sura.id),
            onChanged: (value) {
              setState(() {
                if (value!) {
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
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ];
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveSelection,
        child: const Icon(Icons.save),
      ),
    );
  }
}
