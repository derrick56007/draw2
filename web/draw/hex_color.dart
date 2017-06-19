part of play;

class HexColor {
  final int r;
  final int g;
  final int b;

  const HexColor._internal(this.r, this.g, this.b);

  factory HexColor(String hexCode) {
    if (hexCode.startsWith('#')) {
      hexCode = hexCode.substring(1);
    }

    var hexDigits = hexCode.split('');

    int r = int.parse(hexDigits.sublist(0, 2).join(), radix: 16);
    int g = int.parse(hexDigits.sublist(2, 4).join(), radix: 16);
    int b = int.parse(hexDigits.sublist(4).join(), radix: 16);

    return new HexColor._internal(r, g, b);
  }

  String toString() => '($r,$g,$b)';
}
