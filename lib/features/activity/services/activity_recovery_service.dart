import '../controllers/activity_recorder.dart';
import '../controllers/live_activity_controller.dart';

class ActivityRecoveryService {
  final ActivityRecorder recorder;
  final LiveActivityController controller;

  ActivityRecoveryService({
    required this.recorder,
    required this.controller,
  });

  void recoverIfNeeded() {
    if (!recorder.hasActiveStream) return;

    if (!recorder.canResumeSafely) {
      discard();
    }
  }

  Future<void> discard() async {
    controller.forceIdle();
    await recorder.discardSession();
  }

  Future<void> resume() async {
    await recorder.resume();
  }
}
