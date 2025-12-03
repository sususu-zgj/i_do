import 'package:flutter/material.dart';
import 'package:i_do/i_do_api.dart';

class BaseAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;

  const BaseAppBar({super.key, required this.title, this.actions, this.leading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionTheme = theme.appBarTheme.actionsIconTheme?.copyWith(
      color: theme.colorScheme.primary,
    );
    
    return IDoAPI.buildGlassWidget(
      
      child: AppBar(
        elevation: 0,
        scrolledUnderElevation: 4,
        backgroundColor: Colors.transparent,
        actionsPadding: const EdgeInsets.only(right: 8.0),
        title: title,
        actions: actions,
        leading: leading,
        actionsIconTheme: actionTheme,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
