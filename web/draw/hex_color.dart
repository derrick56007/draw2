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

    final hexDigits = hexCode.split('');

    final r = int.parse(hexDigits.sublist(0, 2).join(), radix: 16);
    final g = int.parse(hexDigits.sublist(2, 4).join(), radix: 16);
    final b = int.parse(hexDigits.sublist(4).join(), radix: 16);

    return new HexColor._internal(r, g, b);
  }

  @override
  String toString() => '($r,$g,$b)';
}
