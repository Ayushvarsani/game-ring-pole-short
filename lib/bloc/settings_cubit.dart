import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/audio_service.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  static const _soundKey = 'soundEnabled';
  static const _musicKey = 'musicEnabled';
  static const _vibrateKey = 'vibrateEnabled';

  SettingsCubit() : super(const SettingsState()) {
    _loadSettings();
  }

  // ── Initialisation ────────────────────────────────────────────────────────

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

    // Init AudioService with persisted values so it is ready immediately.
    await AudioService.instance.init(
      soundEnabled: soundEnabled,
      musicEnabled: musicEnabled,
    );
  }

  // ── Toggles ───────────────────────────────────────────────────────────────

  Future<void> toggleSound(bool enabled) async {
    emit(state.copyWith(soundEnabled: enabled));
    await AudioService.instance.setSoundEnabled(enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, enabled);
  }

  Future<void> toggleMusic(bool enabled) async {
    emit(state.copyWith(musicEnabled: enabled));
    await AudioService.instance.setMusicEnabled(enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicKey, enabled);
  }

  Future<void> toggleVibration(bool enabled) async {
    // Emit before persisting so the UI reflects the new state instantly.
    emit(state.copyWith(vibrateEnabled: enabled));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrateKey, enabled);
  }

  // ── Sound helpers (called throughout the app) ─────────────────────────────

  /// Short UI tap / button click sound.
  void playClickSound() {
    AudioService.instance.playTap();
  }

  /// Liquid-pour sound — call when a pour animation begins.
  void playPourSound() {
    AudioService.instance.playPour();
  }

  /// Victory fanfare — call when a level is won.
  void playWinSound() {
    AudioService.instance.playWin();
  }

  /// Fail tone — call on game-over.
  void playFailSound() {
    AudioService.instance.playFail();
  }

  /// Single-bottle solved chime — call when a bottle becomes fully sorted.
  void playBottleSolvedSound() {
    AudioService.instance.playBottleSolved();
  }

  // ── Haptic helpers (gated by vibrateEnabled) ──────────────────────────────

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

  // ── App lifecycle ─────────────────────────────────────────────────────────

  /// Call from the top-level app widget when the app goes to background.
  Future<void> onAppPaused() => AudioService.instance.onAppPaused();

  /// Call from the top-level app widget when the app returns to foreground.
  Future<void> onAppResumed() => AudioService.instance.onAppResumed();

  @override
  Future<void> close() async {
    await AudioService.instance.dispose();
    return super.close();
  }
}
