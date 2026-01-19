import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PowerController extends StateNotifier<bool> {
  PowerController()
      : _player = AudioPlayer(),
        _tickPlayer = AudioPlayer(),
        super(false) {
    _player.setPlayerMode(PlayerMode.lowLatency);
    _player.setReleaseMode(ReleaseMode.stop);
    _tickPlayer.setPlayerMode(PlayerMode.lowLatency);
    _tickPlayer.setReleaseMode(ReleaseMode.stop);
  }

  final AudioPlayer _player;
  final AudioPlayer _tickPlayer;
  bool _locked = false;
  Timer? _lockTimer;

  Future<void> playTick() async {
    try {
      await _tickPlayer.play(
        AssetSource('audio/tune_tick.wav'),
        volume: 1.0,
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {
      // Ignore audio errors to avoid blocking the UI.
    }
  }

  Future<bool?> toggle() async {
    if (_locked) return null;
    _locked = true;
    _lockTimer?.cancel();

    final nextState = !state;
    state = nextState;

    try {
      await _player.play(
        AssetSource(nextState ? 'audio/power_on.wav' : 'audio/power_off.wav'),
        volume: 0.3,
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {
      // Ignore audio errors to avoid blocking the UI.
    }

    _lockTimer = Timer(const Duration(milliseconds: 350), () {
      _locked = false;
    });
    return nextState;
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    _player.dispose();
    _tickPlayer.dispose();
    super.dispose();
  }
}

final powerStateProvider =
    StateNotifierProvider<PowerController, bool>((ref) {
  return PowerController();
});
