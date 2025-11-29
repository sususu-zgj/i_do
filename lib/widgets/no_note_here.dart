import 'package:flutter/material.dart';

class NoNoteHere extends StatelessWidget {
  const NoNoteHere({
    super.key,
    this.icon,
    this.message,
  });

  final Widget? icon;
  final Widget? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null)
          IconTheme(
            data: IconTheme.of(context).copyWith(
              color: Theme.of(context).colorScheme.outline,
              size: 80,
            ),
            child: icon!,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            DefaultTextStyle(
              style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.outline,
              ),
              child: message!,
            ),
          ],
        ],
      ),
    );
  }
}