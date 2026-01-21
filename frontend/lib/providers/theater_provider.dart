import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fallback seed advices (shown when no related comments available)
const kFallbackAdvices = [
  '당신의 이야기를 들어줄 누군가가 있어요. 혼자가 아니에요.',
  '지금 이 순간도 지나가요. 조금만 더 버텨주세요.',
  '완벽하지 않아도 괜찮아요. 있는 그대로의 당신이 소중해요.',
  '힘든 감정을 느끼는 것도 용기예요. 잘하고 있어요.',
  '오늘 하루도 수고했어요. 당신은 충분히 잘하고 있어요.',
  '작은 것에서 위로를 찾아보세요. 따뜻한 음료 한 잔 어떨까요?',
  '누군가는 당신을 응원하고 있어요. 멀리서라도요.',
  '지금 느끼는 감정은 당신만의 것이에요. 소중히 안아주세요.',
  '쉬어도 괜찮아요. 잠시 멈춰도 괜찮아요.',
  '당신의 존재 자체가 누군가에게는 위로가 돼요.',
];

class StarPin {
  const StarPin({
    required this.id,
    required this.title,
    required this.preview,
    required this.tags,
    this.author = '익명',
    this.isComfort = false,
    this.storyId,
  });

  final String id;
  final String title;
  final String preview;
  final List<String> tags;
  /// Author name (for comfort messages)
  final String author;
  /// True if this is a comfort message (comment), false if story
  final bool isComfort;
  /// Story ID this comfort belongs to (for navigation)
  final String? storyId;
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
    state = state.copyWith(isActive: false, selectedPin: null);
  }

  // ✅ 상세에서 pop으로 돌아올 때 theater 복귀
  void resume() {
    if (state.pins.isEmpty) return; // pins 없으면 복귀할 게 없음
    state = state.copyWith(isActive: true, selectedPin: null);
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
