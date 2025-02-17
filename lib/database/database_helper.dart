import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_review_app/models/sura_model.dart';
import 'dart:convert';

class DatabaseHelper {
  static final _prefsKey = 'QuranReviewPrefs';
  static final _selectedSurasKey = 'selected_suras';
  static final _allSurasKey = 'all_suras';
  static final _preferencesKey = 'preferences';

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  // Sura operations
  Future<void> addSelectedSura(Sura sura) async {
    final selected = await getSelectedSuras();
    selected.add(sura);
    await _saveSelectedSuras(selected);
  }

  Future<void> removeSelectedSura(int id) async {
    final selected = await getSelectedSuras();
    selected.removeWhere((s) => s.id == id);
    await _saveSelectedSuras(selected);
  }

  Future<List<Sura>> getSelectedSuras() async {
    final prefs = await _prefs;
    final jsonString = prefs.getString(_selectedSurasKey) ?? '[]';
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((e) => Sura.fromJson(e)).toList();
  }

  Future<void> _saveSelectedSuras(List<Sura> suras) async {
    final prefs = await _prefs;
    final jsonList = suras.map((s) => s.toJson()).toList();
    await prefs.setString(_selectedSurasKey, json.encode(jsonList));
  }

  // All Suras operations
  Future<List<Sura>> getAllSuras() async {
    final prefs = await _prefs;
    final jsonString = prefs.getString(_allSurasKey) ?? '[]';
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((e) => Sura.fromJson(e)).toList();
  }

  Future<void> addSura(Sura sura) async {
    final prefs = await _prefs;
    final allSuras = await getAllSuras();
    allSuras.add(sura);
    await prefs.setString(_allSurasKey, json.encode(allSuras.map((e) => e.toJson()).toList()));
  }

  Future<void> updateSura(Sura sura) async {
    final prefs = await _prefs;
    final allSuras = await getAllSuras();
    final index = allSuras.indexWhere((s) => s.id == sura.id);
    if (index != -1) {
      allSuras[index] = sura;
      await prefs.setString(_allSurasKey, json.encode(allSuras.map((e) => e.toJson()).toList()));
    }
  }

  Future<void> deleteSura(int id) async {
    final prefs = await _prefs;
    final allSuras = await getAllSuras();
    allSuras.removeWhere((s) => s.id == id);
    await prefs.setString(_allSurasKey, json.encode(allSuras.map((e) => e.toJson()).toList()));
  }

  // Preferences operations
  Future<void> setPreference(String name, String value) async {
    final prefs = await _prefs;
    final Map<String, dynamic> preferences = await _getPreferences();
    preferences[name] = value;
    await prefs.setString(_preferencesKey, json.encode(preferences));
  }

  Future<String?> getPreference(String name) async {
    final Map<String, dynamic> preferences = await _getPreferences();
    return preferences[name]?.toString();
  }

  Future<Map<String, dynamic>> _getPreferences() async {
    final prefs = await _prefs;
    final jsonString = prefs.getString(_preferencesKey) ?? '{}';
    return Map<String, dynamic>.from(json.decode(jsonString));
  }

  // Language preferences
  Future<void> setSelectedLanguage(String languageCode) async {
    await setPreference('selectedLanguage', languageCode);
  }

  Future<String?> getSelectedLanguage() async {
    return await getPreference('selectedLanguage');
  }

  // Sura status operations
  Future<void> updateSuraReviewedStatus(int suraId, bool isCompleted) async {
    final selected = await getSelectedSuras();
    final index = selected.indexWhere((s) => s.id == suraId);
    if (index != -1) {
      selected[index].isCompleted = isCompleted;
      await _saveSelectedSuras(selected);
    }
  }
}