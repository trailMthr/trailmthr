import 'activity_state.dart';

enum ActivityEvent {
  userStart,
  systemReady,
  userPause,
  userResume,
  userStop,
  systemFinalizeOk,
  systemCrashDetected,
  userResumeAfterCrash,
  userFinishAfterCrash,
  systemFail,
}

class ActivityTransition {
  final ActivityState from;
  final ActivityEvent event;
  final ActivityState to;
  const ActivityTransition(this.from, this.event, this.to);
}

class ActivityStateMachine {
  static const List<ActivityTransition> _allowed = [
    ActivityTransition(ActivityState.idle, ActivityEvent.userStart, ActivityState.preparing),
    ActivityTransition(ActivityState.preparing, ActivityEvent.systemReady, ActivityState.recording),

    ActivityTransition(ActivityState.recording, ActivityEvent.userPause, ActivityState.paused),
    ActivityTransition(ActivityState.paused, ActivityEvent.userResume, ActivityState.recording),

    ActivityTransition(ActivityState.recording, ActivityEvent.userStop, ActivityState.stopping),
    ActivityTransition(ActivityState.paused, ActivityEvent.userStop, ActivityState.stopping),
    ActivityTransition(ActivityState.stopping, ActivityEvent.systemFinalizeOk, ActivityState.completed),

    ActivityTransition(ActivityState.recording, ActivityEvent.systemCrashDetected, ActivityState.recoverable),
    ActivityTransition(ActivityState.paused, ActivityEvent.systemCrashDetected, ActivityState.recoverable),

    ActivityTransition(ActivityState.recoverable, ActivityEvent.userResumeAfterCrash, ActivityState.recording),
    ActivityTransition(ActivityState.recoverable, ActivityEvent.userFinishAfterCrash, ActivityState.stopping),

    // Failure (explicit honesty)
    ActivityTransition(ActivityState.preparing, ActivityEvent.systemFail, ActivityState.failed),
    ActivityTransition(ActivityState.recording, ActivityEvent.systemFail, ActivityState.failed),
    ActivityTransition(ActivityState.paused, ActivityEvent.systemFail, ActivityState.failed),
    ActivityTransition(ActivityState.stopping, ActivityEvent.systemFail, ActivityState.failed),
    ActivityTransition(ActivityState.recoverable, ActivityEvent.systemFail, ActivityState.failed),
  ];

  static bool canApply(ActivityState from, ActivityEvent event) =>
      _allowed.any((t) => t.from == from && t.event == event);

  static ActivityState apply(ActivityState from, ActivityEvent event) {
    final match = _allowed.where((t) => t.from == from && t.event == event).toList();
    if (match.length != 1) {
      throw StateError('Illegal transition: $from --$event--> (no unique target)');
    }
    return match.single.to;
  }
}
