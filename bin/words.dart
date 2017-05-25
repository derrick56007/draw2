part of server;

class Words {
  static const defaultPath = 'data/data.txt';
  final List<String> list = [];

  Words({path: defaultPath}) {
    new File(path).readAsLines()
      ..then((words) {
        list
          ..addAll(words)
          ..shuffle();
      })
      ..catchError((e) {
        print('Error reading file path: $path');
      });
  }
}
