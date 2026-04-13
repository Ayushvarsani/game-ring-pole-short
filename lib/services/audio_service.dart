import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Centralised audio service for all game sound effects and background music.
///
/// Design notes:
/// - BGM uses a single [AudioPlayer] in loop mode.
/// - We track BGM state ourselves alongside the player's native state to
///   survive Android audio-focus interruptions and lifecycle events.
/// - SFX uses a small round-robin pool per type for low-latency, overlap-free
///   playback.
/// - All methods are safe to call at any time; they silently no-op when the
///   relevant feature is disabled.
class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  // ── BGM ───────────────────────────────────────────────────────────────────
  static const _bgmAsset = 'audio/bgm.wav';
  static const _bgmVolume = 0.55;

  late AudioPlayer _bgm;
  bool _bgmReady = false;   // true after the first successful play()
  bool _musicEnabled = true;

  // ── SFX pool ──────────────────────────────────────────────────────────────
  static const int _poolSize = 3;
  final Map<SfxType, List<AudioPlayer>> _pool = {};
  final Map<SfxType, int> _poolIndex = {};
  bool _sfxReady = false;

  bool _soundEnabled = true;

  // ── Initialisation ────────────────────────────────────────────────────────

  bool _initialised = false;

  /// Call once after [SharedPreferences] is loaded.
  /// Safe to call again — subsequent calls are ignored.
  Future<void> init({
    required bool soundEnabled,
    required bool musicEnabled,
  }) async {
    if (_initialised) {
      // Just update flags and apply music state.
      _soundEnabled = soundEnabled;
      _musicEnabled = musicEnabled;
      await _applyMusicState();
      return;
    }
    _initialised = true;
    _soundEnabled = soundEnabled;
    _musicEnabled = musicEnabled;

    await _initBgm();
    await _initSfxPool();

    if (_musicEnabled) {
      await _playBgm();
    }
  }

  Future<void> _initBgm() async {
    _bgm = AudioPlayer();
    // Must await setReleaseMode – on Android this registers the looping flag
    // with the native layer before the first play() call.
    await _bgm.setReleaseMode(ReleaseMode.loop);
    await _bgm.setVolume(_bgmVolume);
  }

  Future<void> _initSfxPool() async {
    for (final type in SfxType.values) {
      _pool[type] = List.generate(_poolSize, (_) => AudioPlayer());
      _poolIndex[type] = 0;
    }
    _sfxReady = true;
  }

  // ── BGM control ───────────────────────────────────────────────────────────

  /// Start the BGM track from the beginning.
  Future<void> _playBgm() async {
    try {
      // play() always starts from the beginning and works from any state
      // (stopped, paused, completed).
      await _bgm.play(AssetSource(_bgmAsset));
      _bgmReady = true;
    } catch (e) {
      debugPrint('[AudioService] BGM play() failed: $e');
    }
  }

  /// Resume BGM if paused, otherwise start fresh.
  Future<void> _resumeBgm() async {
    if (!_bgmReady) {
      await _playBgm();
      return;
    }
    final ps = _bgm.state;
    if (ps == PlayerState.paused) {
      try {
        await _bgm.resume();
      } catch (_) {
        // resume() can fail if audio focus was lost; fall back to fresh play.
        await _playBgm();
      }
    } else if (ps == PlayerState.stopped || ps == PlayerState.completed) {
      // Player was stopped externally (e.g. audio focus loss on Android).
      await _playBgm();
    }
    // If already playing, nothing to do.
  }

  /// Pause BGM (keeps source loaded so resume() is instant).
  Future<void> _pauseBgm() async {
    if (!_bgmReady) return;
    try {
      await _bgm.pause();
    } catch (_) {}
  }

  /// Apply the current [_musicEnabled] flag to the player immediately.
  Future<void> _applyMusicState() async {
    if (_musicEnabled) {
      await _resumeBgm();
    } else {
      await _pauseBgm();
    }
  }

  // ── Public settings API ───────────────────────────────────────────────────

  /// Called by [SettingsCubit] when the Sound toggle changes.
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
  }

  /// Called by [SettingsCubit] when the Music toggle changes.
  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    await _applyMusicState();
  }

  // ── App lifecycle ─────────────────────────────────────────────────────────

  /// Call when the app moves to background.
  Future<void> onAppPaused() async {
    await _pauseBgm();
  }

  /// Call when the app returns to foreground.
  Future<void> onAppResumed() async {
    if (_musicEnabled) {
      await _resumeBgm();
    }
  }

  // ── Disposal ──────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    _initialised = false;
    _bgmReady = false;
    _sfxReady = false;
    await _bgm.dispose();
    for (final players in _pool.values) {
      for (final p in players) {
        await p.dispose();
      }
    }
    _pool.clear();
    _poolIndex.clear();
  }

  // ── SFX ───────────────────────────────────────────────────────────────────

  void playTap() => _playSfx(SfxType.tap);
  void playPour() => _playSfx(SfxType.pour);
  void playWin() => _playSfx(SfxType.win);
  void playFail() => _playSfx(SfxType.fail);
  void playBottleSolved() => _playSfx(SfxType.bottleSolved);

  void _playSfx(SfxType type) {
    if (!_soundEnabled || !_sfxReady) return;
    final players = _pool[type];
    if (players == null || players.isEmpty) return;

    final idx = _poolIndex[type]!;
    final player = players[idx];
    _poolIndex[type] = (idx + 1) % _poolSize;

    // stop() → play() so we never block on a still-playing slot.
    player.stop().then((_) {
      player.play(AssetSource(type.assetPath), volume: type.volume);
    });
  }
}

// ── SFX catalogue ─────────────────────────────────────────────────────────────

enum SfxType {
  tap('audio/tap.wav', 0.7),
  pour('audio/pour.wav', 0.55),
  win('audio/win.wav', 0.82),
  fail('audio/fail.wav', 0.70),
  bottleSolved('audio/bottle_solved.wav', 0.75);

  const SfxType(this.assetPath, this.volume);

  final String assetPath;
  final double volume;
}
