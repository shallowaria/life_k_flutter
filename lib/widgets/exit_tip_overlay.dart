import 'package:flutter/material.dart';

class ExitTipOverlay {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  static void show(BuildContext context) {
    if (_isShowing) return;
    _isShowing = true;

    // 获取当前的 OverlayState
    final overlay = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (context) => _ExitToastWidget(
        onDismissed: () {
          _overlayEntry?.remove();
          _overlayEntry = null;
          _isShowing = false;
        },
      ),
    );

    overlay.insert(_overlayEntry!);
  }
}

class _ExitToastWidget extends StatefulWidget {
  final VoidCallback onDismissed;
  const _ExitToastWidget({required this.onDismissed});

  @override
  State<_ExitToastWidget> createState() => _ExitToastWidgetState();
}

class _ExitToastWidgetState extends State<_ExitToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    // 4秒总时长：3秒常驻 + 1秒淡出
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _opacity = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 75), // 前75%时间不透明度为1
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 25,
      ), // 后25%时间淡出
    ]).animate(_controller);

    _controller.forward().then((_) => widget.onDismissed());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: FadeTransition(
            opacity: _opacity,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "再次操作退出人生K线",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
