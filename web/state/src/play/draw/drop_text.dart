part of play;

class DropText {
  static final rand = new Math.Random();

  final Element element;
  final Point velocity;
  final Point position;

  final num angularVel;
  num rotation = 0;

  DropText._internal(
      this.element, this.velocity, this.position, this.angularVel) {
    element.style
      ..top = '${position.y}px'
      ..left = '${position.x}px';

    document.body.children.add(element);
  }

  factory DropText(String text) {
    final element =
        new Element.html('<div class="drop-text noselect">${text}</div>');

    final position = new Point(rand.nextInt(window.innerWidth),
        -element.getBoundingClientRect().height);

    final velocity = new Point(0.0, 2.25);
    final angularVel = rand.nextDouble() * .5 * (rand.nextBool() ? -1 : 1);

    return new DropText._internal(element, velocity, position, angularVel);
  }

  update() {
    position.y += velocity.y;
    position.x += velocity.x;
    rotation += angularVel;

    element.style
      ..top = '${position.y}px'
      ..left = '${position.x}px'
      ..transform = 'rotate(${rotation}deg)';
  }

  remove() {
    element.remove();
  }
}
