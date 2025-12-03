import 'package:flutter/material.dart';
import 'package:i_do/i_do_api.dart';

class BaseThemeDrawer extends StatelessWidget {
  final Widget child;
  const BaseThemeDrawer({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return theme.brightness == Brightness.dark 
    ? IDoAPI.buildGlassWidget(
      blurSigma: 6,
      borderRadius: BorderRadiusGeometry.horizontal(
        end: Radius.circular(16)
      ),
      child: Drawer(
        backgroundColor: colorScheme.surfaceContainerLow.withValues(alpha: 0.2),
        child: SafeArea(
          child: child,
        ),
      )
    )
    : Drawer(
      child: SafeArea(
        child: child,
      ),
    );
  }
}