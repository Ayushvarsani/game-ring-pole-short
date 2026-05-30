import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final bool soundEnabled;
  final bool musicEnabled;
  final bool vibrateEnabled;

  const SettingsState({
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.vibrateEnabled = true,
  });

  SettingsState copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
    bool? vibrateEnabled,
  }) {
    return SettingsState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      vibrateEnabled: vibrateEnabled ?? this.vibrateEnabled,
    );
  }

  @override
  List<Object?> get props => [soundEnabled, musicEnabled, vibrateEnabled];
}
