import 'package:flutter/material.dart';
import 'package:i_do/i_do_api.dart';

class BaseThemeFloatingActionButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final String? tooltip;

  const BaseThemeFloatingActionButton({
    super.key, 
    required this.child, 
    this.onPressed, 
    this.onLongPress,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onLongPress: onLongPress,
      child: IDoAPI.buildGlassWidget(
        borderRadius: BorderRadius.circular(16),
        blurSigma: 4,
        child: FloatingActionButton(
          onPressed: onPressed,
          elevation: 0,
          focusElevation: 0,
          hoverElevation: 0,
          highlightElevation: 0,
          tooltip: tooltip,
          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
          child: child,
        ),
      ),
    );
  } 
}