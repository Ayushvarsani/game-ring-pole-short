import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final bool soundEnabled;
  final bool vibrateEnabled;

  const SettingsState({this.soundEnabled = true, this.vibrateEnabled = true});

  SettingsState copyWith({bool? soundEnabled, bool? vibrateEnabled}) {
    return SettingsState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrateEnabled: vibrateEnabled ?? this.vibrateEnabled,
    );
  }

  @override
  List<Object?> get props => [soundEnabled, vibrateEnabled];
}
