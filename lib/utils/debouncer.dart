// lib/utils/debouncer.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Debouncer para evitar múltiplas chamadas em sequência
/// Útil para search bars e campos de texto
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({this.milliseconds = 400});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}