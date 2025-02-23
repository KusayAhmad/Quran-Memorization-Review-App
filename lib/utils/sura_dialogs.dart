import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:quran_review_app/database/database_helper.dart';
import 'package:quran_review_app/models/sura_model.dart';

Future<void> showAddSuraDialog(
  BuildContext context,
  Function() onSuraAdded, // Callback لإعادة تحميل البيانات بعد الإضافة
  AppLocalizations localizations, // الترجمة
) async {
  String suraName = '';
  double suraPages = 0.0;

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(localizations.addNewSura), // استخدام الترجمة
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: localizations.suraName),
              // استخدام الترجمة
              onChanged: (value) => suraName = value,
            ),
            TextField(
              decoration: InputDecoration(
                  labelText: localizations.numberOfPages), // استخدام الترجمة
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) => suraPages = double.tryParse(value) ?? 0.0,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel), // استخدام الترجمة
          ),
          TextButton(
            onPressed: () async {
              if (suraName.isNotEmpty && suraPages > 0) {
                final dbHelper = DatabaseHelper();
                await dbHelper.insertSura(
                  name: suraName,
                  pages: suraPages,
                );
                onSuraAdded(); // استدعاء callback لإعادة تحميل البيانات
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(localizations.invalidInput), // استخدام الترجمة
                  ),
                );
              }
            },
            child: Text(localizations.add), // استخدام الترجمة
          ),
        ],
      );
    },
  );
}

Future<void> showEditSuraDialog(
  BuildContext context,
  Sura sura,
  Function(Sura) onUpdate,
  AppLocalizations localizations,
) async {
  String suraName = sura.name;
  double suraPages = sura.pages;

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(localizations.edit), // استخدام الترجمة
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: localizations.suraName),
              // استخدام الترجمة
              controller: TextEditingController(text: sura.name),
              onChanged: (value) => suraName = value,
            ),
            TextField(
              decoration: InputDecoration(
                  labelText: localizations.numberOfPages), // استخدام الترجمة
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              controller: TextEditingController(text: sura.pages.toString()),
              onChanged: (value) => suraPages = double.tryParse(value) ?? 0.0,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(localizations.cancel), // استخدام الترجمة
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text(localizations.update), // استخدام الترجمة
            onPressed: () {
              if (suraName.isNotEmpty && suraPages > 0) {
                final updatedSura = Sura(
                  id: sura.id,
                  name: suraName,
                  pages: suraPages,
                  isCompleted: sura.isCompleted,
                );
                onUpdate(updatedSura); // استدعاء callback لتحديث السورة
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      );
    },
  );
}
