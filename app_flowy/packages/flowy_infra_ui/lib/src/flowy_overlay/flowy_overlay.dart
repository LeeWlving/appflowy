import 'package:dartz/dartz.dart' show Tuple3;
import 'package:flutter/material.dart';

/// Specifies how overlay are anchored to the SourceWidget
enum AnchorDirection {
  // Corner aligned with a corner of the SourceWidget
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,

  // Edge aligned with a edge of the SourceWidget
  topWithLeftAligned,
  topWithCenterAligned,
  topWithRightAligned,
  rightWithTopAligned,
  rightWithCenterAligned,
  rightWithBottomAligned,
  bottomWithLeftAligned,
  bottomWithCenterAligned,
  bottomWithRightAligned,
  leftWithTopAligned,
  leftWithCenterAligned,
  leftWithBottomAligned,

  // Custom position
  custom,
}

/// The behavior of overlay when user tapping system back button
enum OnBackBehavior {
  /// Won't handle the back action
  none,

  /// Animate to get the user's attention
  alert,

  /// Intercept the back action and abort directly
  abort,

  /// Intercept the back action and dismiss overlay
  dismiss,
}

final GlobalKey<FlowyOverlayState> _key = GlobalKey<FlowyOverlayState>();

/// Invoke this method in app generation process
TransitionBuilder overlayManagerBuilder() {
  return (context, child) {
    assert(child != null, 'Child can\'t be null.');
    return FlowyOverlay(key: _key, child: child!);
  };
}

abstract class FlowyOverlayDelegate {
  void didRemove();
}

class FlowyOverlay extends StatefulWidget {
  const FlowyOverlay({
    Key? key,
    required this.child,
    this.barrierColor = Colors.transparent,
  }) : super(key: key);

  final Widget child;

  final Color? barrierColor;

  static FlowyOverlayState of(
    BuildContext context, {
    bool rootOverlay = false,
  }) {
    FlowyOverlayState? overlayManager;
    if (rootOverlay) {
      overlayManager = context.findRootAncestorStateOfType<FlowyOverlayState>() ?? overlayManager;
    } else {
      overlayManager = overlayManager ?? context.findAncestorStateOfType<FlowyOverlayState>();
    }

    assert(() {
      if (overlayManager == null) {
        throw FlutterError(
          'Can\'t find overlay manager in current context, please check if already wrapped by overlay manager.',
        );
      }
      return true;
    }());
    return overlayManager!;
  }

  static FlowyOverlayState? maybeOf(
    BuildContext context, {
    bool rootOverlay = false,
  }) {
    FlowyOverlayState? overlayManager;
    if (rootOverlay) {
      overlayManager = context.findRootAncestorStateOfType<FlowyOverlayState>() ?? overlayManager;
    } else {
      overlayManager = overlayManager ?? context.findAncestorStateOfType<FlowyOverlayState>();
    }

    return overlayManager;
  }

  @override
  FlowyOverlayState createState() => FlowyOverlayState();
}

class FlowyOverlayState extends State<FlowyOverlay> {
  List<Tuple3<Widget, String, FlowyOverlayDelegate?>> _overlayList = [];

  void insert({
    required Widget widget,
    required String identifier,
    FlowyOverlayDelegate? delegate,
  }) {
    setState(() {
      _overlayList.add(Tuple3(widget, identifier, delegate));
    });
  }

  void remove(String identifier) {
    setState(() {
      final index = _overlayList.indexWhere((ele) => ele.value2 == identifier);
      _overlayList.removeAt(index).value3?.didRemove();
    });
  }

  void removeAll() {
    setState(() {
      for (var ele in _overlayList.reversed) {
        ele.value3?.didRemove();
      }
      _overlayList = [];
    });
  }

  void _markDirty() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final overlays = _overlayList.map((ele) => ele.value1);
    final children = <Widget>[
      widget.child,
      if (overlays.isNotEmpty)
        Container(
          color: widget.barrierColor,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _handleTapOnBackground,
          ),
        ),
    ];

    return Stack(
      children: children..addAll(overlays),
    );
  }

  void _handleTapOnBackground() {
    removeAll();
  }
}