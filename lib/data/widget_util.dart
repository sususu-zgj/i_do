import 'dart:async';

import 'package:flutter/material.dart';

class WidgetUtil {
  /// 在 Overlay 中显示一个样式与 SnackBar 一致的提示（带动画、主题支持、可选 action）
  static void showSnackBar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => OverlaySnackBar(
        message: message,
        duration: duration,
        actionLabel: actionLabel,
        onAction: () {
          onAction?.call();
          if (entry.mounted) entry.remove();
        },
        onDismissed: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );

    overlay.insert(entry);
  }
}

class OverlaySnackBar extends StatefulWidget {
  final String message;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismissed;

  const OverlaySnackBar({
    super.key,
    required this.message,
    required this.duration,
    this.actionLabel,
    this.onAction,
    required this.onDismissed,
  });

  @override
  State<OverlaySnackBar> createState() => _OverlaySnackBarState();
}

class _OverlaySnackBarState extends State<OverlaySnackBar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnim;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _offsetAnim = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // 先入场
    _controller.forward();

    // 自动退出（留一点时间给退出动画）
    _timer = Timer(widget.duration, () async {
      if (mounted) {
        await _controller.reverse();
        widget.onDismissed();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snackTheme = theme.snackBarTheme;

    // 样式：尽量使用 SnackBarTheme 提供的配置
    final backgroundColor = snackTheme.backgroundColor ?? theme.colorScheme.onSurface;
    final elevation = snackTheme.elevation ?? 6;
    final shape = snackTheme.shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(4));
    final contentTextStyle = snackTheme.contentTextStyle ?? theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.surface);
    final actionTextColor = snackTheme.actionTextColor ?? theme.colorScheme.secondary;

    return Positioned(
      left: 16,
      right: 16,
      bottom: 0,
      child: SafeArea(
        top: false,
        bottom: false,
        child: SlideTransition(
          position: _offsetAnim,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: ShapeDecoration(
                color: backgroundColor,
                shape: shape,
                shadows: [
                  BoxShadow(color: Colors.black26, blurRadius: elevation.toDouble(), offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: DefaultTextStyle(
                      style: contentTextStyle ?? const TextStyle(color: Colors.white),
                      child: Text(
                        widget.message,
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ),
                  if (widget.actionLabel != null && widget.onAction != null)
                    TextButton(
                      onPressed: widget.onAction,
                      style: TextButton.styleFrom(
                        foregroundColor: actionTextColor,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(widget.actionLabel!),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}