import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:i_do/data/edit_data.dart';
import 'package:i_do/data/note.dart';
import 'package:i_do/data/setting.dart';
import 'package:i_do/page/note_edit_page.dart';
import 'package:i_do/page/search_page.dart';
import 'package:i_do/page/setting_page.dart';
import 'package:i_do/page/tags_page.dart';
import 'package:provider/provider.dart';

class IDoAPI {
  IDoAPI._();

  static double appBarElevation = 0.55;

  static double cardElevation = 2.5;

  static void showSnackBar({ 
    required BuildContext context,
    required String message,
    Duration duration = const Duration(milliseconds: 800),
    String? actionLabel,
    VoidCallback? onAction,
    VoidCallback? onDismissed,
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

  static void openEditPage(BuildContext context, { Note? note }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return ChangeNotifierProvider(
            create: (context) => EditData(note: note),
            child: const NoteEditPage(),
          );
        },
      ),
    );
  }

  static void openSettingPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return const SettingPage();
        },
      ),
    );
  }

  static void openTagsPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return const TagsPage();
        },
      ),
    );
  }

  static void openSearchPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return const SearchPage();
        },
      ),
    );
  }  

  static Widget buildGlassWidget({required Widget child, double blurSigma = 12}) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: child
      ),
    );
  }

  static Widget buildASWidget({
    required Widget child,
    Key? key,
    Duration duration = const Duration(milliseconds: 300),
    Duration? reverseDuration,
    Curve switchInCurve = Curves.linear,
    Curve switchOutCurve = Curves.linear,
    Widget Function(Widget child, Animation<double> animation)? transitionBuilder
  }) {
    final animated = Setting().enableAnimations;

    if (animated) {
      return AnimatedSwitcher(
        key: key,
        duration: duration,
        switchInCurve: switchInCurve,
        switchOutCurve: switchOutCurve,
        reverseDuration: reverseDuration,
        transitionBuilder: transitionBuilder ?? (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: child,
      );
    } else {
      return child;
    }
  }

  static Widget buildAnimatedPadding({
    required Widget child, 
    required EdgeInsetsGeometry padding, 
    Duration duration = const Duration(milliseconds: 300)
  }) {
    final animated = Setting().enableAnimations;

    if (animated) {
      return AnimatedPadding(
        duration: duration,
        padding: padding,
        child: child,
      );
    } else {
      return Padding(
        padding: padding,
        child: child,
      );
    }
  }

  static Widget buildAnimatedContainer({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    double? width,
    double? height,
    BoxDecoration? decoration,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    AlignmentGeometry? alignment,
  }) {
    final animated = Setting().enableAnimations;

    if (animated) {
      return AnimatedContainer(
        duration: duration,
        curve: curve,
        width: width,
        height: height,
        decoration: decoration,
        padding: padding,
        margin: margin,
        alignment: alignment,
        child: child,
      );
    } else {
      return Container(
        width: width,
        height: height,
        decoration: decoration,
        padding: padding,
        margin: margin,
        alignment: alignment,
        child: child,
      );
    }
  }

}

class OverlaySnackBar extends StatefulWidget {
  final String message;
  final Duration duration;
  final Duration animationDuration;
  final String? actionLabel;
  final SnackBarThemeData? snackBarTheme;
  final VoidCallback? onAction;
  final VoidCallback? onDismissed;

  const OverlaySnackBar({
    super.key,
    required this.message,
    this.duration = const Duration(seconds: 2),
    this.animationDuration = const Duration(milliseconds: 250),
    this.actionLabel,
    this.snackBarTheme,
    this.onAction,
    required this.onDismissed,
  });

  @override
  State<OverlaySnackBar> createState() => _OverlaySnackBarState();
}

class _OverlaySnackBarState extends State<OverlaySnackBar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnim;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
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
        widget.onDismissed?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snackTheme = widget.snackBarTheme ?? theme.snackBarTheme;

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