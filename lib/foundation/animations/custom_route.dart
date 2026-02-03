import 'package:file_manager/foundation/animations/rotate_transition.dart';
import 'package:file_manager/foundation/animations/scale_transition.dart';
import 'package:file_manager/foundation/animations/size_transition.dart';
import 'package:file_manager/foundation/animations/slide_down_transition.dart';
import 'package:file_manager/foundation/animations/slide_left_transition.dart';
import 'package:file_manager/foundation/animations/slide_right_transition.dart';
import 'package:file_manager/foundation/animations/slide_up_transition.dart';
import 'package:flutter/material.dart';
import 'fade_transition.dart';

enum AnimationType {
  fade,
  slideRight,
  slideLeft,
  slideUp,
  slideDown,
  scale,
  rotate,
  size,
}

class CustomRoute {
  static PageRouteBuilder generate(Widget page, AnimationType type) {
    switch (type) {
      case AnimationType.fade:
        return FadeTransitionRoute(page);
      case AnimationType.slideRight:
        return SlideRightTransition(page);
      case AnimationType.slideLeft:
        return SlideLeftTransition(page);
      case AnimationType.slideUp:
        return SlideUpTransition(page);
      case AnimationType.slideDown:
        return SlideDownTransition(page);
      case AnimationType.scale:
        return ScaleTransitionRoute(page);
      case AnimationType.rotate:
        return RotateTransitionRoute(page);
      case AnimationType.size:
        return SizeTransitionRoute(page);
    }
  }
}
