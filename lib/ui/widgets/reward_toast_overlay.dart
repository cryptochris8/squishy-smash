import 'dart:async';

import 'package:flutter/material.dart';

import '../../game/systems/reward_event.dart';
import 'reward_toast.dart';

/// Listens to a [Stream] of `RewardEvent`s and renders each as a
/// floating `RewardToast`. Multiple in-flight toasts stack vertically
/// — newest at the bottom of the column — so a kid who triggers a
/// milestone + a duplicate at once sees both.
///
/// Decoupled from `SquishyGame` (takes the bare stream) so it's
/// trivially widget-testable: pass any `Stream<RewardEvent>` and
/// verify toast lifecycle without needing Flame.
///
/// Owns its subscription lifecycle: subscribes in initState, cancels
/// in dispose. Drops events silently if the widget is unmounted.
class RewardToastOverlay extends StatefulWidget {
  const RewardToastOverlay({super.key, required this.events});

  final Stream<RewardEvent> events;

  @override
  State<RewardToastOverlay> createState() => _RewardToastOverlayState();
}

class _RewardToastOverlayState extends State<RewardToastOverlay> {
  StreamSubscription<RewardEvent>? _subscription;
  final List<RewardEvent> _active = <RewardEvent>[];

  @override
  void initState() {
    super.initState();
    _subscription = widget.events.listen(_onReward);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onReward(RewardEvent event) {
    if (!mounted) return;
    setState(() => _active.add(event));
  }

  void _onToastComplete(int eventId) {
    if (!mounted) return;
    setState(() => _active.removeWhere((e) => e.id == eventId));
  }

  @override
  Widget build(BuildContext context) {
    if (_active.isEmpty) return const SizedBox.shrink();
    // Bottom-anchored, centered. Above the FAB area but below the
    // HUD so it doesn't block the score readout. SafeArea protects
    // notches / home indicator.
    return Positioned(
      left: 0,
      right: 0,
      bottom: 96,
      child: SafeArea(
        child: IgnorePointer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final event in _active)
                Padding(
                  key: ValueKey<int>(event.id),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: RewardToast(
                    event: event,
                    onComplete: () => _onToastComplete(event.id),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
