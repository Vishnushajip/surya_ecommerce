import 'package:flutter/material.dart';

class AppAnimations {
  // Duration constants
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  // Curve constants for smooth animations
  static const Curve smoothCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve decelerateCurve = Curves.decelerate;
  static const Curve accelerateCurve = Curves.easeIn;

  // Fade animation
  static Widget fadeTransition({
    required Widget child,
    required Animation<double> animation,
    Curve curve = Curves.easeInOut,
  }) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: curve),
      child: child,
    );
  }

  // Slide animation
  static Widget slideTransition({
    required Widget child,
    required Animation<Offset> animation,
    Curve curve = Curves.easeInOut,
  }) {
    return SlideTransition(position: animation, child: child);
  }

  // Scale animation
  static Widget scaleTransition({
    required Widget child,
    required Animation<double> animation,
    Curve curve = Curves.easeInOut,
  }) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: animation, curve: curve),
      child: child,
    );
  }

  // Animated container helper
  static Widget animatedContainer({
    required Widget child,
    Duration duration = normal,
    Curve curve = smoothCurve,
  }) {
    return AnimatedContainer(duration: duration, curve: curve, child: child);
  }

  // Animated opacity helper
  static Widget animatedOpacity({
    required Widget child,
    required bool visible,
    Duration duration = normal,
    Curve curve = smoothCurve,
  }) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: duration,
      curve: curve,
      child: child,
    );
  }

  // Page transition builder
  static PageRouteBuilder<T> createPageRoute<T>({
    required Widget page,
    Duration duration = normal,
    Curve curve = smoothCurve,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: duration,
    );
  }

  // Staggered animation for list items
  static Animation<double> createStaggeredAnimation({
    required int index,
    required AnimationController controller,
    double staggerInterval = 0.1,
  }) {
    final start = index * staggerInterval;
    final end = start + 0.5;

    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          start.clamp(0.0, 1.0),
          end.clamp(0.0, 1.0),
          curve: smoothCurve,
        ),
      ),
    );
  }

  // Animated switcher with scale
  static Widget animatedSwitcher({
    required Widget child,
    Duration duration = normal,
    Key? key,
  }) {
    return AnimatedSwitcher(
      key: key,
      duration: duration,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: child,
    );
  }

  // Hero animation builder
  static Widget heroAnimation({required String tag, required Widget child}) {
    return Hero(tag: tag, child: child);
  }

  // Smooth scroll to top
  static void scrollToTop(ScrollController controller) {
    controller.animateTo(0, duration: slow, curve: decelerateCurve);
  }

  // Smooth scroll to position
  static void scrollToPosition(ScrollController controller, double position) {
    controller.animateTo(position, duration: slow, curve: decelerateCurve);
  }
}
