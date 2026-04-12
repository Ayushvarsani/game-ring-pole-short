import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  static const _soundKey = 'soundEnabled';
  static const _musicKey = 'musicEnabled';
  static const _vibrateKey = 'vibrateEnabled';

  // For background music
  final AudioPlayer _bgmPlayer = AudioPlayer();

  SettingsCubit() : super(const SettingsState()) {
    _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final soundEnabled = prefs.getBool(_soundKey) ?? true;
    final musicEnabled = prefs.getBool(_musicKey) ?? true;
    final vibrateEnabled = prefs.getBool(_vibrateKey) ?? true;
    emit(
      SettingsState(
        soundEnabled: soundEnabled,
        musicEnabled: musicEnabled,
        vibrateEnabled: vibrateEnabled,
      ),
    );

    _updateBgmPlayback(musicEnabled);
  }

  Future<void> toggleSound(bool enabled) async {
    emit(state.copyWith(soundEnabled: enabled));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, enabled);
  }

  Future<void> toggleMusic(bool enabled) async {
    emit(state.copyWith(musicEnabled: enabled));
    _updateBgmPlayback(enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicKey, enabled);
  }

  Future<void> toggleVibration(bool enabled) async {
    // Emit before persisting so callers (e.g. settings switch) see the new value
    // immediately — otherwise triggerLightHaptic() runs with stale state.
    emit(state.copyWith(vibrateEnabled: enabled));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrateKey, enabled);
  }

  void _updateBgmPlayback(bool play) {
    if (play) {
      // NOTE: To hear background music, you must have an audio asset at
      // assets/audio/bgm.mp3, uncomment the lines below,
      // and add the asset directory to your pubspec.yaml.
      // try {
      //   _bgmPlayer.play(AssetSource('audio/bgm.mp3'));
      // } catch (_) {}
    } else {
      _bgmPlayer.pause();
    }
  }

  // --- Sound & Haptics Helpers ---

  void playClickSound() {
    if (state.soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  void triggerLightHaptic() {
    if (state.vibrateEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  void triggerHeavyHaptic() {
    if (state.vibrateEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  void triggerSelectionHaptic() {
    if (state.vibrateEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Future<void> close() {
    _bgmPlayer.dispose();
    return super.close();
  }
}
