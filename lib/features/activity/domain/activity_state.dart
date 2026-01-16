enum ActivityState {
  idle,
  preparing,
  recording,
  paused,
  stopping,
  completed,
  recoverable,
  failed,
}

extension ActivityStateX on ActivityState {
  bool get isActive => this == ActivityState.recording || this == ActivityState.paused;
  bool get isTerminal => this == ActivityState.completed || this == ActivityState.failed;
  bool get canRecordPoints => this == ActivityState.recording;
}
