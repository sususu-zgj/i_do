import 'package:flutter/material.dart';
import 'package:i_do/data/home_data_.dart';
import 'package:i_do/data/note.dart';
import 'package:i_do/i_do_api.dart';

class NoteItem extends StatelessWidget {
  const NoteItem({
    super.key,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 2.0,
    this.shape,
    this.animated = false,
    required this.note,
    required this.leadingShown,
    required this.trailingShown,
    required this.selected,
    required this.dateShown,
    required this.tagsShown,
    required this.toggleFinish,
    this.onSelect,
    this.onTap,
    this.onLongPress,
    this.onDelete,
    this.onFinish,
  });

  final Color? foregroundColor;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final bool animated;

  final Note note;
  final bool leadingShown;
  final bool trailingShown;
  final bool selected;
  final bool dateShown;
  final bool tagsShown;
  final bool toggleFinish;

  final void Function(bool?)? onSelect;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;
  final VoidCallback? onFinish;

  Widget _bulidTitle() {
    return Text(
      note.title,
      overflow: TextOverflow.ellipsis,
      maxLines: HomeData().columnsCount == 1 ? 1 : 3,
    );
  }

  Widget _buildFinishIcon() {
    return SizedBox(
      height: 40,
      width: 40,
      child: IDoAPI.buildASWidget(
        child: note.isFinished
          ? toggleFinish && trailingShown 
            ? IconButton(key: const ValueKey('check'), onPressed: onFinish, icon: const Icon(Icons.check)) 
            : const Icon(Icons.check, key: ValueKey('check'),)
          : toggleFinish && trailingShown
            ? IconButton(key: const ValueKey('circle'), onPressed: onFinish, icon: const Icon(Icons.circle_outlined)) 
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget? _buildSubTitle(BuildContext context) {
    if (!dateShown && !tagsShown) return null;

    bool vertical = HomeData().columnsCount != 1;

    final theme = Theme.of(context);
    final tagColor = theme.colorScheme.primary;

    List<InlineSpan> spans = [];

    // 日期
    if (dateShown) {
      spans.add(
        TextSpan(
          text: '${note.dateTime.year}-${note.dateTime.month}-${note.dateTime.day}',
          style: theme.textTheme.bodyMedium?.copyWith(color: foregroundColor),
        ),
      );
    }

    // 间隔
    if (dateShown && tagsShown && note.tags.isNotEmpty) {
      spans.add(vertical ? const TextSpan(text: '\n') : const TextSpan(text: '   '));
    }

    // 标签
    if (tagsShown && note.tags.isNotEmpty) {
      for (int i = 0; i < note.tags.length; i++) {
        spans.add(
          TextSpan(
            text: '#',
            style: theme.textTheme.bodyLarge?.copyWith(color: foregroundColor ?? tagColor, fontWeight: FontWeight.bold),
          ),
        );
        spans.add(
          TextSpan(
            text: note.tags[i],
            style: theme.textTheme.bodyMedium?.copyWith(color: foregroundColor ?? tagColor),
          ),
        );
        if (i != note.tags.length - 1) {
          spans.add(const TextSpan(text: ' '));
        }
      }
    }

    if (vertical) {
      return RichText(
        overflow: TextOverflow.clip,
        maxLines: null,
        text: TextSpan(
          children: spans,
        ),
      );
    }

    return SizedBox(
      height: 28,
      child: RichText(
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        text: TextSpan(
          children: spans,
        ),
      ),
    );
  }

  Widget _buildOption() {
    return PopupMenuButton<int>(
      onSelected: (value) {
        switch (value) {
          case 1:
            onFinish?.call();
          case 2:
            onSelect?.call(!(selected));
          case 3:
            onDelete?.call();
        }
      },
      itemBuilder: (context) => [
        note.isFinished 
        ? const PopupMenuItem<int>(
          value: 1,
          child: Text('Unfinish'),
        )
        : const PopupMenuItem<int>(
          value: 1,
          child: Text('Finish'),
        ), 
        const PopupMenuItem<int>(
          value: 2,
          child: Text('Select'),
        ),
        const PopupMenuItem<int>(
          value: 3,
          child: Text('Delete'),
        ),
      ],
    );
  }

  Widget _buildItemHorinize(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          Expanded(child: _bulidTitle()),
          _buildFinishIcon(),
        ],
      ),
      subtitle: _buildSubTitle(context),
      trailing: trailingShown ? _buildOption() : null,
      onTap: onTap,
      onLongPress: onLongPress,
      shape: shape,
    );
  }

  Widget _buildItemVertical(BuildContext context) {
    return ListTile(
      title: _bulidTitle(),
      subtitle: _buildSubTitle(context),
      onTap: onTap,
      onLongPress: onLongPress,
      shape: shape,
    );
  }

  @override
  Widget build(BuildContext context) {
    final columnCount = HomeData().columnsCount;
    bool vertical = columnCount != 1;
    
    return CardTheme(
      color: backgroundColor,
      shape: shape,
      elevation: elevation,
      child: ListTileTheme(
        data: ListTileTheme.of(context).copyWith(
        iconColor: foregroundColor,
        shape: shape,
        textColor: foregroundColor,
          isThreeLine: vertical,
          titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: foregroundColor,
          ),
        ),
        child: Card(
          child: IDoAPI.buildAnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: columnCount == 1 ? _buildItemHorinize(context) : _buildItemVertical(context),
          ),
        ),
      ),
    );
  }
}
