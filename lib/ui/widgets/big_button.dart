import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/service_locator.dart';

class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Wrapping a GestureDetector in `Semantics(button: true)` is
      // what makes VoiceOver / TalkBack treat the widget as a button
      // and announce its label — a bare GestureDetector is invisible
      // to assistive tech. The label uses the same text the button
      // renders so screen-reader and visual experiences match.
      button: true,
      enabled: true,
      label: label,
      onTap: () {
        HapticFeedback.selectionClick();
        ServiceLocator.ui.buttonTap();
        onTap();
      },
      // `excludeSemantics: true` removes the inner Text's child
      // semantics so VoiceOver doesn't read the label twice (once as
      // a button, once as plain text).
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          ServiceLocator.ui.buttonTap();
          onTap();
        },
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
