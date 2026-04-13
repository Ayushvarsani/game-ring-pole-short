/// Dart script to generate minimal WAV audio files for the game.
/// Run with: dart tool/generate_audio.dart
/// Output goes to assets/audio/
library;

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  final dir = Directory('assets/audio');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  // tap.wav – soft click (440 Hz, 80ms, quick decay)
  _writeWav('assets/audio/tap.wav', _sine(440, 0.08, 0.18));

  // pour.wav – bubbling tone (220 Hz vibrato, 350ms)
  _writeWav('assets/audio/pour.wav', _vibrato(220, 6, 0.35, 0.22));

  // win.wav – ascending arpeggio (C5-E5-G5-C6, 600ms)
  _writeWav('assets/audio/win.wav', _arpeggio([523, 659, 784, 1047], 0.6, 0.28));

  // fail.wav – descending minor (A4-F4, 400ms)
  _writeWav('assets/audio/fail.wav', _arpeggio([440, 349], 0.4, 0.26));

  // bottle_solved.wav – short chime (E5, 200ms)
  _writeWav('assets/audio/bottle_solved.wav', _sine(659, 0.20, 0.20));

  // bgm.wav – gentle loop made of layered drone (110 Hz, 3s loop)
  _writeWav('assets/audio/bgm.wav', _bgmLoop(3.0));

  print('✅ Audio assets generated in assets/audio/');
}

const int _sampleRate = 22050;

// ── Generators ───────────────────────────────────────────────────────────────

List<double> _sine(double freq, double duration, double amplitude) {
  final n = (duration * _sampleRate).round();
  return List.generate(n, (i) {
    final t = i / _sampleRate;
    final env = _envelope(i, n);
    return sin(2 * pi * freq * t) * amplitude * env;
  });
}

List<double> _vibrato(
  double freq,
  double lfoRate,
  double duration,
  double amplitude,
) {
  final n = (duration * _sampleRate).round();
  return List.generate(n, (i) {
    final t = i / _sampleRate;
    final lfo = sin(2 * pi * lfoRate * t);
    final env = _envelope(i, n);
    return sin(2 * pi * (freq + lfo * 8) * t) * amplitude * env;
  });
}

List<double> _arpeggio(List<double> freqs, double duration, double amplitude) {
  final n = (duration * _sampleRate).round();
  final perNote = n ~/ freqs.length;
  final samples = <double>[];

  for (int fi = 0; fi < freqs.length; fi++) {
    for (int i = 0; i < perNote; i++) {
      final t = i / _sampleRate;
      final env = _envelope(i, perNote);
      samples.add(sin(2 * pi * freqs[fi] * t) * amplitude * env);
    }
  }

  // Pad to n if needed
  while (samples.length < n) {
    samples.add(0.0);
  }
  return samples;
}

List<double> _bgmLoop(double duration) {
  final n = (duration * _sampleRate).round();
  // Two-oscillator drone: root + fifth
  const amp = 0.12;
  return List.generate(n, (i) {
    final t = i / _sampleRate;
    // Slow fade-in at start, fade-out at end for seamless loop
    double env = 1.0;
    final fadeLen = (0.15 * _sampleRate).round();
    if (i < fadeLen) env = i / fadeLen;
    if (i > n - fadeLen) env = (n - i) / fadeLen;

    final root = sin(2 * pi * 110 * t); // A2
    final fifth = sin(2 * pi * 165 * t) * 0.6; // E3
    final octave = sin(2 * pi * 220 * t) * 0.3; // A3
    return (root + fifth + octave) * amp * env;
  });
}

double _envelope(int i, int n) {
  // Quick attack (5%), sustain, exponential release (last 60%)
  const attackFrac = 0.05;
  const releaseFrac = 0.60;
  final attackEnd = (n * attackFrac).round();
  final releaseStart = (n * (1.0 - releaseFrac)).round();

  if (i < attackEnd) return i / attackEnd;
  if (i > releaseStart) {
    return pow(1.0 - (i - releaseStart) / (n - releaseStart), 1.5).toDouble();
  }
  return 1.0;
}

// ── WAV Writer ────────────────────────────────────────────────────────────────

void _writeWav(String path, List<double> samples) {
  final data = Int16List(samples.length);
  for (int i = 0; i < samples.length; i++) {
    data[i] = (samples[i].clamp(-1.0, 1.0) * 32767).round();
  }

  final byteData = ByteData(44 + data.length * 2);
  int offset = 0;

  void writeStr(String s) {
    for (final c in s.codeUnits) {
      byteData.setUint8(offset++, c);
    }
  }

  void writeUint32(int v) {
    byteData.setUint32(offset, v, Endian.little);
    offset += 4;
  }

  void writeUint16(int v) {
    byteData.setUint16(offset, v, Endian.little);
    offset += 2;
  }

  writeStr('RIFF');
  writeUint32(36 + data.length * 2); // ChunkSize
  writeStr('WAVE');
  writeStr('fmt ');
  writeUint32(16); // Subchunk1Size
  writeUint16(1); // AudioFormat = PCM
  writeUint16(1); // NumChannels = mono
  writeUint32(_sampleRate);
  writeUint32(_sampleRate * 2); // ByteRate
  writeUint16(2); // BlockAlign
  writeUint16(16); // BitsPerSample
  writeStr('data');
  writeUint32(data.length * 2);

  for (int i = 0; i < data.length; i++) {
    byteData.setInt16(offset, data[i], Endian.little);
    offset += 2;
  }

  File(path).writeAsBytesSync(byteData.buffer.asUint8List());
  print('  Generated $path (${(byteData.lengthInBytes / 1024).toStringAsFixed(1)} KB)');
}
