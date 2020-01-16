import 'dart:js';

void toast(String message, [int duration = 2500]) {
  print(message);
  context['Materialize'].callMethod('toast', [message, duration]);
}