import 'package:flutter/material.dart';
import 'package:i_do/data/note.dart';
import 'package:i_do/i_do_api.dart';
import 'package:i_do/widgets/BaseThemeWidget/base_theme_app_bar.dart';
import 'package:i_do/widgets/no_note_here.dart';
import 'package:provider/provider.dart';

class StarredPage extends StatefulWidget {
  const StarredPage({super.key});

  @override
  State<StarredPage> createState() => _StarredPageState();
}

class _StarredPageState extends State<StarredPage> {
  late List<Note> notes;
  Noter? _noter;
  Noter get noter => _noter!;

  bool selecting = false;
  final List<Note> selectedNotes = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_noter != null) return;
    _noter ??= context.watch<Noter>();
    notes = noter.notes.where((note) => note.isStarred && !note.isDeleted).toList();
    
  }

  PreferredSizeWidget _buildAppBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return BaseAppBar(
      title: selecting ? Text('${selectedNotes.length} Selected') : const Text('Starred Notes'),
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
        IDoAPI.buildASWidget(
          child: selecting
            ? IconButton(
                icon: Icon(Icons.star, color: colorScheme.outline,),
                onPressed: _onUnstars
              )
            : const SizedBox.shrink(),
        )
      ]
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

        return _StarredItem(
          note: note,
          selecting: selecting,
          selected: selected,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: shape,
          elevation: elevation,
          iconColor: Colors.amber,
          onTap: () => _onTap(note),
          onLongPress: () => _onLongPress(note),
          onStar: () => _onStar(note),
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
            icon: Icon(Icons.star_border_outlined),
            message: Text('No Starred Notes Yet'),
          ) 
          : _buildBody(),
    );
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

  void _onStar(Note note) {
    note.isStarred = !note.isStarred;
    noter.updateNote(note);
  }

  void _onUnstars() {
    for (var note in selectedNotes) {
      note.isStarred = false;
    }
    noter.updateNotes(selectedNotes);
    selectedNotes.clear();
  }
}

class _StarredItem extends StatelessWidget {
  const _StarredItem({
    required this.note,
    this.selecting = false,
    this.selected = false,
    this.onTap,
    this.onLongPress,
    this.onStar,
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
  final VoidCallback? onStar;

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
        child: ListTile(
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
              ? note.isStarred ? const Icon(Icons.star, color: Colors.amber,) : const Icon(Icons.star_border, color: Colors.amber,)
              : IconButton(
                color: iconColor,
                  icon: note.isStarred ? const Icon(Icons.star) : const Icon(Icons.star_border),
                  onPressed: onStar,
                ),
          onTap: onTap,
          onLongPress: onLongPress,
          subtitle: _buildSubTitle(context),
        ),
      ),
    );
  }
}