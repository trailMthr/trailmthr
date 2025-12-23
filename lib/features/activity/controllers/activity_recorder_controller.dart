import 'activity_recorder.dart';

class ActivityRecorderController {
  static final ActivityRecorderController instance =
      ActivityRecorderController._internal();

  ActivityRecorderController._internal();

  RecorderState _state = RecorderState.initial();

  RecorderState get state => _state;

  bool get isRecording => _state.isRecording;

  // later: start(), pause(), stop(), restore(), etc.
}
