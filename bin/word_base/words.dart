part of word_base;

class Words {
  final List<String> list;

  Words(String category)
      : list = WordBase.mappedCategories[category]..shuffle();
}
