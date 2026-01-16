

extension RecorderStateX on RecorderState {
  bool get isIdle => !isRecording;
  bool get isActive => isRecording || isPaused;
}
