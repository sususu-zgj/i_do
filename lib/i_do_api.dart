import 'dart:ui';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:i_do/data/config.dart';
import 'package:i_do/data/edit_data.dart';
import 'package:i_do/data/note.dart';
import 'package:i_do/page/note_edit_page.dart';
import 'package:i_do/page/recycle_page.dart';
import 'package:i_do/page/search_page.dart';
import 'package:i_do/page/setting_page.dart';
import 'package:i_do/page/starred_page.dart';
import 'package:i_do/page/tags_page.dart';
import 'package:i_do/widgets/overlay_snack_bar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class IDoAPI {
  IDoAPI._();

  static const List<FlexScheme> schemes = [
    FlexScheme.flutterDash,
    FlexScheme.blue,
    FlexScheme.green,
    FlexScheme.shadGreen,
    FlexScheme.mandyRed,
    FlexScheme.blackWhite,
    FlexScheme.shadStone,
  ];

  static Color cardColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return colorScheme.surfaceContainer;
  }

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

  static void openStarredPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return const StarredPage();
        },
      ),
    );
  }

  static void openRecyclePage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return const RecyclePage();
        },
      ),
    );
  }

  static Widget buildGlassWidget({required Widget child, double blurSigma = 8, BorderRadiusGeometry borderRadius = BorderRadius.zero}) {
    return ClipRRect(
      borderRadius: borderRadius,
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

  static Future<String> get storagePath async {
    return (await getApplicationDocumentsDirectory()).path;
  }
}
