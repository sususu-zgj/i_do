import 'package:flutter/material.dart';
import 'package:i_do/data/config.dart';
import 'package:i_do/data/note.dart';
import 'package:i_do/i_do_api.dart';

class NoteItem extends StatelessWidget {
  const NoteItem({
    super.key,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 2.0,
    this.shape,
    required this.note,
    required this.selecting,
    required this.selected,
    required this.toggleFinish,
    this.onSelect,
    this.onTap,
    this.onLongPress,
    this.onDelete,
    this.onFinish,
    this.onStar,
  });

  final Color? foregroundColor;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;

  final Note note;
  final bool selecting;
  final bool selected;
  final bool toggleFinish;

  final void Function(bool?)? onSelect;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;
  final VoidCallback? onFinish;
  final VoidCallback? onStar;

  bool get vertical => AppConfig().columnsCount != 1;

  Widget _bulidTitle(BuildContext context) {
    List<InlineSpan> spans = [];
    if (vertical) {
      spans.add(
        WidgetSpan(
          child: IDoAPI.buildASWidget(
            child: note.isFinished
              ? const Icon(Icons.check, size: 20,)
              : const SizedBox.shrink(),
          ))
        );
    }
    spans.add(
      TextSpan(
        text: note.title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: foregroundColor,
        ),
      ),
    );

    return RichText(
      overflow: TextOverflow.ellipsis,
      maxLines: AppConfig().columnsCount == 1 ? 1 : 3,
      text: TextSpan(
        children: spans,
      ),
    );
  }

  Widget _buildFinishIcon() {
    return SizedBox(
      height: 40,
      width: 40,
      child: IDoAPI.buildASWidget(
        child: note.isFinished
          ? toggleFinish && !selecting 
            ? IconButton(key: const ValueKey('check'), onPressed: onFinish, icon: const Icon(Icons.check)) 
            : const Icon(Icons.check, key: ValueKey('check'),)
          : toggleFinish && !selecting
            ? IconButton(key: const ValueKey('circle'), onPressed: onFinish, icon: const Icon(Icons.circle_outlined)) 
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildSubTitle(BuildContext context) {
    final theme = Theme.of(context);
    final tagColor = theme.colorScheme.primary;

    List<InlineSpan> spans = [];

    // 日期
    spans.add(
      TextSpan(
        text: '${note.dateTime.year}-${note.dateTime.month}-${note.dateTime.day}',
        style: theme.textTheme.bodyMedium?.copyWith(color: foregroundColor),
      ),
    );

    // 间隔
    if (vertical) {
      spans.add(const TextSpan(text: '\n'));
    }
    else {
      spans.add(const TextSpan(text: '   '));
    }


    // 标签
    if ( note.tags.isNotEmpty) {
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
    else {
      spans.add(
        TextSpan(
          text: 'No Tags',
          style: theme.textTheme.bodyMedium?.copyWith(color: foregroundColor?.withValues(alpha: 0.6)),
        ),
      );
    }

    Widget subtitle = vertical 
        ? RichText(
            overflow: TextOverflow.clip,
            maxLines: null,
            text: TextSpan(
              children: spans,
            ),
          ) 
        : SizedBox(
            height: 28,
            child: RichText(
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              text: TextSpan(
                children: spans,
              ),
            ),
          );

    return subtitle;
  }

  Widget _buildOption() {
    return selecting 
    ? SizedBox(
      height: 40,
      width: 40,
      child: Icon(Icons.more_vert, color: foregroundColor,),
    )
    : PopupMenuButton<int>(
      color: foregroundColor,
      onSelected: (value) {
        switch (value) {
          case 1:
            onFinish?.call();
          case 2:
            onSelect?.call(!(selected));
          case 3:
            onDelete?.call();
          case 4:
            onStar?.call();
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
                note.isStarred 
        ? const PopupMenuItem<int>(
          value: 4,
          child: Text('Unstar'),
        )
        : const PopupMenuItem<int>(
          value: 4,
          child: Text('Star'),
        ),
      ],
    );
  }

  Widget _buildStar() {
    return SizedBox(
      height: 40,
      width: 40,
      child: IDoAPI.buildASWidget(
        child: selecting
          ? note.isStarred
            ? const Icon(Icons.star, color: Colors.amber, key: ValueKey('starred'),)
            : const Icon(Icons.star_border, color: Colors.amber, key: ValueKey('unstarred'),)
          : note.isStarred
            ? IconButton(key: const ValueKey('starred'), onPressed: onStar, icon: const Icon(Icons.star, color: Colors.amber)) 
            : IconButton(key: const ValueKey('unstarred'), onPressed: onStar, icon: const Icon(Icons.star_border, color: Colors.amber))
      )
    );
  }

  Widget _buildItemHorinize(BuildContext context) {
    return Stack(
      children: [
        ListTile(
          title: Row(
            children: [
              Expanded(child: _bulidTitle(context)),
              _buildFinishIcon(),
              const SizedBox(width: 8),
            ],
          ),
          subtitle: _buildSubTitle(context),
          onTap: onTap,
          onLongPress: onLongPress,
          shape: shape,
        ),
        Positioned(
          right: 0,
          child: Column(
            children: [
              _buildStar(),
              _buildOption(),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildItemVertical(BuildContext context) {
    return Stack(
      children: [
        ListTile(
          title: _bulidTitle(context),
          subtitle: _buildSubTitle(context),
          onTap: onTap,
          onLongPress: onLongPress,
          shape: shape,
        ),
        Positioned(
          right: 0,
          top: 0,
          child: Column(
            children: [
              _buildStar(),
              _buildOption(),
            ],
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final columnCount = AppConfig().columnsCount;
    
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
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: columnCount == 1 ? _buildItemHorinize(context) : _buildItemVertical(context),
          ),
        ),
      ),
    );
  }
}
