import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:quran_review_app/database/database_helper.dart';
import 'package:quran_review_app/models/sura_model.dart';

Future<void> showAddSuraDialog(BuildContext context,
    Function() onSuraAdded,
    AppLocalizations localizations,) async {
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          TextEditingController nameController = TextEditingController();
          TextEditingController pagesController = TextEditingController();

          return AlertDialog(
            title: Text(localizations.addNewSura),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration:
                      InputDecoration(labelText: localizations.suraName),
                  controller: nameController,
                ),
                TextField(
                  decoration:
                      InputDecoration(labelText: localizations.numberOfPages),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  controller: pagesController,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(localizations.cancel),
              ),
              TextButton(
                onPressed: () async {
                  final suraName = nameController.text.trim();
                  final suraPages =
                      double.tryParse(pagesController.text.trim()) ?? 0.0;

                  if (suraName.isNotEmpty && suraPages > 0) {
                    final dbHelper = DatabaseHelper.instance;
                    await dbHelper.insertSura(
                      name: suraName,
                      pages: suraPages,
                    );

                    onSuraAdded();

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(localizations.invalidInput)),
                    );
                  }
                },
                child: Text(localizations.add),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> showEditSuraDialog(BuildContext context,
    Sura sura,
    Function(Sura) onUpdate,
    AppLocalizations localizations,) async {
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          TextEditingController nameController =
              TextEditingController(text: sura.name);
          TextEditingController pagesController =
              TextEditingController(text: sura.pages.toString());

          return AlertDialog(
            title: Text(localizations.edit),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration:
                      InputDecoration(labelText: localizations.suraName),
                  controller: nameController,
                ),
                TextField(
                  decoration:
                      InputDecoration(labelText: localizations.numberOfPages),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  controller: pagesController,
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text(localizations.cancel),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text(localizations.update),
                onPressed: () {
                  final suraName = nameController.text.trim();
                  final suraPages =
                      double.tryParse(pagesController.text.trim()) ?? 0.0;

                  if (suraName.isNotEmpty && suraPages > 0) {
                    final updatedSura = Sura(
                      id: sura.id,
                      name: suraName,
                      pages: suraPages,
                      isCompleted: sura.isCompleted,
                    );
                    onUpdate(updatedSura);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}
