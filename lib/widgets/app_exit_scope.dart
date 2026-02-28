import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'exit_tip_overlay.dart';

class AppExitScope extends StatefulWidget {
  const AppExitScope({super.key, required this.child});

  final Widget child;

  @override
  State<AppExitScope> createState() => _AppExitScopeState();
}

class _AppExitScopeState extends State<AppExitScope> {
  DateTime? _lastPressedAt;
  static const int _pressIntervalSeconds = 4;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final now = DateTime.now();
        if (_lastPressedAt == null ||
            now.difference(_lastPressedAt!) >
                const Duration(seconds: _pressIntervalSeconds)) {
          _lastPressedAt = now;
          ExitTipOverlay.show(context);
        } else {
          SystemNavigator.pop();
        }
      },
      child: widget.child,
    );
  }
}
