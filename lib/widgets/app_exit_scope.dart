import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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
    // 使用 PopScope 替换 BackButtonListener
    return PopScope(
      canPop: false, // 核心：设为 false，彻底阻止系统默认的直接退出行为
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        // didPop 为 true 表示路由已经成功出栈（系统已经处理了），就不需要我们管了
        if (didPop) return;

        // 1. 如果 GoRouter 还有路由可 pop（比如在 /result 页面），交还给它处理，回到 /input
        if (GoRouter.of(context).canPop()) {
          GoRouter.of(context).pop();
          return;
        }

        // 2. 已在根页面，开始处理防误触退出逻辑
        final now = DateTime.now();
        if (_lastPressedAt == null ||
            now.difference(_lastPressedAt!) >
                const Duration(seconds: _pressIntervalSeconds)) {
          // 第一次点击，或者距离上次点击超过了 4 秒
          _lastPressedAt = now;
          ExitTipOverlay.show(context);
        } else {
          // 4秒内第二次点击，彻底退出 App
          await SystemNavigator.pop();
        }
      },
      child: widget.child,
    );
  }
}
