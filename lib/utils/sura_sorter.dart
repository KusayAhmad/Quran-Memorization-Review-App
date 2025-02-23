import '../models/sura_model.dart';

class SuraSorter {
  static List<Sura> sortSuras(List<Sura> suras, String sortMode) {
    return List.from(suras)
      ..sort((a, b) {
        int aNum = int.tryParse(a.name) ?? 0;
        int bNum = int.tryParse(b.name) ?? 0;
        return sortMode == 'asc' ? aNum.compareTo(bNum) : bNum.compareTo(aNum);
      });
  }
}
