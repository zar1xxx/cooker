import 'package:flutter/material.dart';

/// An adaptive AppBar title widget per R8-03 and D-057.
///
/// Ensures the title does not overflow or clip when text is scaled up (e.g. 2.0x):
/// - Fits titles on a single line.
/// - Uses [FittedBox] with [BoxFit.scaleDown] and a minimum scale of 0.8.
/// - If text still exceeds available width at 0.8 scale, truncates cleanly with ellipsis.
class AdaptiveAppBarTitle extends StatelessWidget {
  const AdaptiveAppBarTitle(
    this.text, {
    super.key,
    this.style,
    this.minScale = 0.8,
  });

  final String text;
  final TextStyle? style;
  final double minScale;

  @override
  Widget build(BuildContext context) {
    if (text.length <= 16) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(text, maxLines: 1, style: style),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxChildWidth = (minScale > 0 && maxW.isFinite)
            ? maxW / minScale
            : double.infinity;

        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxChildWidth),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        );
      },
    );
  }
}
