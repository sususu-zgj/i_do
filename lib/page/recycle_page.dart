import 'package:flutter/material.dart';
import 'package:i_do/data/note.dart';
import 'package:i_do/i_do_api.dart';
import 'package:i_do/widgets/BaseThemeWidget/base_theme_app_bar.dart';
import 'package:i_do/widgets/no_note_here.dart';
import 'package:provider/provider.dart';

class RecyclePage extends StatefulWidget {
  const RecyclePage({super.key});

  @override
  State<RecyclePage> createState() => _RecyclePageState();
}

class _RecyclePageState extends State<RecyclePage> {
  late List<Note> notes;
  final List<Note> selectedNotes = [];
  bool selecting = false;
  Noter? _noter;
  Noter get noter => _noter!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _noter ??= context.watch<Noter>();
    notes = noter.notes.where((note) => note.isDeleted).toList();
  }

  PreferredSizeWidget _buildAppBar() {
    return BaseAppBar(
      title: selecting ? Text('${selectedNotes.length} Selected') : const Text('Recycle'),
      leading: selecting
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  selecting = false;
                  selectedNotes.clear();
                });
              },
            )
          : null,
      actions: [
        IconButton(
          color: Theme.of(context).colorScheme.primary,
          icon: const Icon(Icons.restore),
          onPressed: _onRecover,
          tooltip: 'Recover',
        ),
        IconButton(
          color: Theme.of(context).colorScheme.error,
          icon: const Icon(Icons.delete_forever),
          onPressed: _onDeleteAll,
          tooltip: 'Delete All',
        ),
      ],
    );
  }

  Widget _buildBody() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        final selected = selectedNotes.contains(note);
        final backgroundColor = selected ? colorScheme.primaryContainer : null;
        final foregroundColor = selected ? colorScheme.onPrimaryContainer : null;
        final elevation = selected ? 6.0 : 2.0;
        final shape = RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: isDark ? BorderSide(
            color: selected ? colorScheme.primaryContainer : colorScheme.outline.withValues(alpha: 0.05),
            width: 1,
          ) : BorderSide.none,
        );

        return _RecycleItem(
          note: note,
          selecting: selecting,
          selected: selected,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          iconColor: colorScheme.error,
          elevation: elevation,
          shape: shape,
          onDelete: () => _onDelete(note),
          onTap: () => _onTap(note),
          onLongPress: () => _onLongPress(note),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: notes.isEmpty 
          ? const NoNoteHere(
            icon: Icon(Icons.delete_outline),
            message: Text('No Notes in Recycle Bin Yet'),
          )
          : _buildBody(),
    );
  }

  void _onDelete(Note note) async {
    final del = await showDialog(context: context, 
      builder: (context) => AlertDialog(
        title: Text('Are you want to delete "${note.title}" ever?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text('Yes'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text('No'),
          )
        ],
      ),
    );
    if (del==true) {
      Noter().removeNote(note).then(
        (value) {
          if (value && mounted) {
            IDoAPI.showSnackBar(context: context, message: '${note.title} has been deleted permanently');
          }
        },
      );
    }
  }

  void _onRecover() async {
    final del = await showDialog(context: context, 
      builder: (context) => AlertDialog(
        title: Text('Are you want to recover ${selecting ? selectedNotes.length : 'ALL'} notes?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text('Yes'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text('No'),
          )
        ],
      ),
    ) ?? false;
    if (!del) return;
    for (final note in selecting ? selectedNotes : notes) {
      note.isDeleted = false;
    }
    noter.updateNotes(selecting ? selectedNotes : notes).then((value) {
      if (value && mounted) {
        IDoAPI.showSnackBar(context: context, message: '${(selecting ? selectedNotes.length : notes.length)} notes have been recovered');
      }
    });
  }

  void _onTap(Note note) {
    if (selecting) {
      setState(() {
        if (selectedNotes.contains(note)) {
          selectedNotes.remove(note);
        } else {
          selectedNotes.add(note);
        }
      });
    } else {
      IDoAPI.openEditPage(context, note: note);
    }
  }

  void _onLongPress(Note note) {
    setState(() {
      selecting = true;
      if (selectedNotes.contains(note)) {
        selectedNotes.remove(note);
      } else {
        selectedNotes.add(note);
      } 
    });
  }

  void _onDeleteAll() async {
    final del = await showDialog(context: context, 
      builder: (context) => AlertDialog(
        title: Text('Are you want to delete ${selecting ? selectedNotes.length : 'ALL'} notes ever?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text('Yes'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text('No'),
          )
        ],
      ),
    );
    if (del == true) {
      Noter().removeNotes(selecting ? selectedNotes : notes).then((value) {
        if (value && mounted) {
          IDoAPI.showSnackBar(context: context, message: '${selecting ? selectedNotes.length : notes.length} notes have been deleted permanently');
        }
        if (value) selectedNotes.clear();
      });
    }
  }
}

class _RecycleItem extends StatelessWidget {
  const _RecycleItem({
    required this.note,
    this.selecting = false,
    this.selected = false,
    this.onTap,
    this.onLongPress,
    this.onDelete,
    this.foregroundColor,
    this.backgroundColor,
    this.iconColor,
    this.shape,
    this.elevation,
  });

  final Note note;
  final bool selecting;
  final bool selected;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final Color? iconColor;
  final ShapeBorder? shape;
  final double? elevation;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;

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
    spans.add(const TextSpan(text: '   '));
    
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

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor,
      shape: shape,
      elevation: elevation,
      child: IDoAPI.buildAnimatedContainer(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: SizedBox(
                width: 30,
                height: 30,
                child: note.isStarred
                  ? const Icon(Icons.star, color: Colors.amber,)
                  : const Icon(Icons.star_border, color: Colors.amber,),
              )
            ),
            ListTile(
              iconColor: foregroundColor,
              shape: shape,
              textColor: foregroundColor,
              titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: foregroundColor,
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(note.title,),
                  ),
                  if (note.isFinished) const Icon(Icons.check, size: 20,),
                ],
              ),
              trailing: selecting
                  ? Icon(Icons.delete, color: iconColor,)
                  : IconButton(
                    color: iconColor,
                      icon: const Icon(Icons.delete),
                      onPressed: onDelete,
                    ),
              onTap: onTap,
              onLongPress: onLongPress,
              subtitle: _buildSubTitle(context),
            ),
          ],
        ),
      ),
    );
  }
}