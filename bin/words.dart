part of server;

class Words {
  static const defaultPath = 'data.txt';
  final List<String> list;

  Words({path: defaultPath}) : list = new File(path).readAsLinesSync() {
    list.shuffle();
  }
}
