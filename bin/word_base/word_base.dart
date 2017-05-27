library word_base;

part 'cat1.dart';
part 'words.dart';

class WordBase {
  static const categories = const [cat1];

  static var mappedCategories = <String, List<String>>{};

  static const categoryNameIndex = 0;

  static init() {
    for (var category in categories) {
      var list = category.split('\n');

      var trimmed = [];

      for (var word in list) {
        trimmed.add(word.trim());
      }

      mappedCategories[list.removeAt(categoryNameIndex)] = trimmed;
    }
  }
}