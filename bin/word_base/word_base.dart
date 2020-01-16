library word_base;

part 'cat1.dart';

part 'words.dart';

class WordBase {
  static const categories = [cat1];

  static var mappedCategories = <String, List<String>>{};

  static const categoryNameIndex = 0;

  static void init() {
    for (var category in categories) {
      final list = category.split('\n');

      final trimmed = <String>[];

      for (var word in list) {
        final trimmedWord = word.trim();

        if (trimmedWord.isNotEmpty) {
          trimmed.add(trimmedWord);
        }
      }

      mappedCategories[trimmed.removeAt(categoryNameIndex)] = trimmed;
    }
  }
}
