import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class StarPin {
  const StarPin({
    required this.id,
    required this.title,
    required this.preview,
    required this.tags,
  });

  final String id;
  final String title;
  final String preview;
  final List<String> tags;
}

class TheaterState {
  const TheaterState({
    this.isActive = false,
    this.pins = const [],
    this.selectedPin,
  });

  final bool isActive;
  final List<StarPin> pins;
  final StarPin? selectedPin;

  TheaterState copyWith({
    bool? isActive,
    List<StarPin>? pins,
    StarPin? selectedPin,
  }) {
    return TheaterState(
      isActive: isActive ?? this.isActive,
      pins: pins ?? this.pins,
      selectedPin: selectedPin,
    );
  }
}

class TheaterController extends StateNotifier<TheaterState> {
  TheaterController() : super(const TheaterState());

  final Random _random = Random();
  List<StarPin> _cachedPins = const [];

  void enter({required List<StarPin> pins}) {
    _cachedPins = List<StarPin>.unmodifiable(pins);
    state = TheaterState(isActive: true, pins: pins, selectedPin: null);
  }

  void exit() {
    state = const TheaterState();
  }

  void resume() {
    if (_cachedPins.isEmpty) return;
    state = TheaterState(isActive: true, pins: _cachedPins, selectedPin: null);
 }
  void selectPin(StarPin? pin) {
    state = state.copyWith(selectedPin: pin);
  }

  int randomInt(int max) => _random.nextInt(max);
}

final theaterProvider =
    StateNotifierProvider<TheaterController, TheaterState>((ref) {
  return TheaterController();
});
