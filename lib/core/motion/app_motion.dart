import 'package:flutter/material.dart';

/// One place for animation timings, so the whole app moves the same way.
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 140);
  static const medium = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 520);
  static const count = Duration(milliseconds: 900);

  static const standard = Curves.easeOutCubic;
  static const pop = Curves.easeOutBack;

  /// True when the user asked the system to reduce motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [duration], or zero when motion is reduced.
  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}