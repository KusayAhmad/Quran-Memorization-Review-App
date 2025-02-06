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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Suras for Review'),
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
