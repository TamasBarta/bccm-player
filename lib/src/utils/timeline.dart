import 'dart:math';

import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/src/utils/debouncer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:flutter/material.dart';

import 'package:bccm_player/src/utils/num.dart';

class TimelineHelper {
  final bool seeking;
  final double currentScrub;
  final double duration;
  final int actualTimeMs;

  /// The fraction of the duration that the player is "currently" at.
  /// By "currently" meaning the actual time or the requested time if seeking.
  final double timeFraction;
  final Future Function() seekToScrubbed;
  final void Function(double targetMs) scrubTo;
  final void Function(double milliseconds) scrubToRelative;

  TimelineHelper({
    required this.seeking,
    required this.currentScrub,
    required this.duration,
    required this.timeFraction,
    required this.actualTimeMs,
    required this.seekToScrubbed,
    required this.scrubTo,
    required this.scrubToRelative,
  });
}

class _TimelineHook extends Hook<TimelineHelper> {
  const _TimelineHook({
    required this.playerController,
    required this.seeking,
    required this.currentScrub,
    required this.seekScheduler,
  });

  final BccmPlayerController playerController;
  final ValueNotifier<bool> seeking;
  final ValueNotifier<double> currentScrub;
  final OneAsyncAtATime seekScheduler;

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends HookState<TimelineHelper, _TimelineHook> {
  @override
  void initHook() {
    super.initHook();
  }

  @override
  TimelineHelper build(BuildContext context) {
    final actualTimeMs = safeInt(hook.playerController.value.playbackPositionMs ?? 0);
    final duration = max(
      0.0,
      safeDouble(
        hook.playerController.value.currentMediaItem?.metadata?.durationMs ?? hook.playerController.value.playbackPositionMs?.toDouble() ?? 1.0,
      ),
    );
    final timeFraction = !duration.isFinite || duration <= 0
        ? 0.0
        : clampDouble(
            (hook.seeking.value ? hook.currentScrub.value : actualTimeMs.toDouble()) / duration,
            0,
            1,
          );

    Future<void> seekToScrubbed() async {
      if (!context.mounted) return;
      final actualTargetMs = hook.currentScrub.value;
      await hook.playerController.seekTo(Duration(milliseconds: (actualTargetMs).round()));
      if (context.mounted && !hook.seekScheduler.hasPending) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          if (!context.mounted) return;
          hook.currentScrub.value = 0;
          hook.seeking.value = false;
        });
      }
    }

    void scrubTo(double targetMs) {
      if ((hook.currentScrub.value - targetMs).abs() < 500) {
        return;
      }
      hook.seeking.value = true;
      hook.currentScrub.value = clampDouble(targetMs, 0, duration);
      hook.seekScheduler.runWhenCurrentIsDone(seekToScrubbed);
    }

    void scrubToRelative(double milliseconds) {
      final baseTime = hook.seeking.value ? hook.currentScrub.value : actualTimeMs;
      final double targetMs = baseTime + milliseconds;
      scrubTo(targetMs);
    }

    return TimelineHelper(
      duration: duration,
      seeking: hook.seeking.value,
      currentScrub: hook.currentScrub.value,
      actualTimeMs: actualTimeMs,
      timeFraction: timeFraction,
      scrubTo: scrubTo,
      scrubToRelative: scrubToRelative,
      seekToScrubbed: seekToScrubbed,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

TimelineHelper useTimeline(BccmPlayerController playerController) {
  final seeking = useState(false);
  final currentScrub = useState(0.0);
  final seekScheduler = useMemoized(() => OneAsyncAtATime());

  // Dispose
  useEffect(() => () => seekScheduler.reset(), []);

  useListenableSelector(
    playerController,
    () => [
      (playerController.value.playbackPositionMs ?? 0 / 500).round(),
      playerController.value.currentMediaItem?.metadata?.durationMs,
    ].toString(),
  );

  return use(_TimelineHook(
    playerController: playerController,
    seeking: seeking,
    currentScrub: currentScrub,
    seekScheduler: seekScheduler,
  ));
}
