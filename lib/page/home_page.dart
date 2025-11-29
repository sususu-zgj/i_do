import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:i_do/data/config.dart';
import 'package:i_do/data/note.dart';
import 'package:i_do/data/searcher.dart';
import 'package:i_do/i_do_api.dart';
import 'package:i_do/widgets/HomePage/home_app_bar.dart';
import 'package:i_do/widgets/HomePage/home_page_drawer.dart';
import 'package:i_do/widgets/HomePage/note_item.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  // 数据
  bool isSelecting = false;
  Noter? _noter;
  AppConfig? _homeData;
  Searcher? _searcher;
  final List<Note> selectedNotes = [];

  Noter get noter => _noter!;
  AppConfig get homeData => _homeData!;
  Searcher get searcher => _searcher!;

  // 动画
  late AnimationController _controller;
  late Animation<double> _blurAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _blurAnimation = Tween<double>(begin: 16.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _noter ??= context.watch<Noter>();
    _searcher ??= context.watch<Searcher>();
    _homeData ??= context.watch<AppConfig>();
  }

  Widget? _buildFloatingActionButton() {
    return homeData.isEditButtonFloating ? GestureDetector(
      onLongPress: () => homeData.isEditButtonFloating = false,
      child: FloatingActionButton(
        onPressed: () => IDoAPI.openEditPage(context),
        tooltip: 'Create Note',
        child: const Icon(Icons.edit),
      ),
    ) : null;
  }

  Widget _buildSelectBar() {
    final color = Theme.of(context).colorScheme.surfaceContainer;
    return Container(
      height: 40,
      color: color,
      child: Row(
        children: [
          SizedBox(width: 8),
          Text('${selectedNotes.length} selected'),
          TextButton(
            onPressed: _onSelectAll,
            child: Text('Select All'),
          ),
          TextButton(
            onPressed: _onNotesDelete,
            child: Text('Delete'),
          ),
          Expanded(child: SizedBox.expand()),
          PopupMenuButton<int>(
            onSelected: (value) {
              switch (value) {
                case 0:
                  for (var note in selectedNotes) {
                    note.isFinished = true;
                  }
                  Noter().updateNotes(selectedNotes, reclassify: false);
                  break;
                case 1:
                  for (var note in selectedNotes) {
                    note.isFinished = false;
                  }
                  Noter().updateNotes(selectedNotes, reclassify: false);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<int>(
                value: 0,
                child: Text('Finish'),
              ),
              const PopupMenuItem<int>(
                value: 1,
                child: Text('Unfinish'),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => setState(() {
              isSelecting = false;
              selectedNotes.clear();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (noter.notes.isEmpty) return const _NoNoteExist();

    final showFinish = homeData.isFinishShown;
    final showUnfinish = homeData.isUnfinishShown;

    // 筛选
    List<Note> notes = searcher.results.where((note) {
      if (note.isFinished && showFinish) return true;
      if (!note.isFinished && showUnfinish) return true;
      return false;
    }).toList();
    switch (homeData.sortMode) {
      case AppConfig.SORT_TITLE:
        notes.sort((a, b) => a.title.compareTo(b.title) * (homeData.isSortReverse ? -1 : 1));
      case AppConfig.SORT_DATE:
        notes.sort((a, b) => b.dateTime.compareTo(a.dateTime) * (homeData.isSortReverse ? -1 : 1));
      case AppConfig.SORT_DEFAULT:
        if (homeData.isSortReverse) {
          notes = notes.reversed.toList();
        }
    }

    selectedNotes.removeWhere((note) => !notes.contains(note));

    if (notes.isEmpty) return const _NoNoteFound();

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IDoAPI.buildASWidget(
      duration: const Duration(milliseconds: 700),
      reverseDuration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                final opacity = 1.0 - animation.value;
                return IgnorePointer(
                  child: Container(
                    color: colorScheme.surface.withValues(alpha: opacity),
                  ),
                );
              },
            )
          ],
        );
      },
      child: MasonryGridView.count(
        key: homeData.columnsCount == 1 ? const PageStorageKey('home_note_list') : const PageStorageKey('home_note_grid'),
        crossAxisCount: homeData.columnsCount,
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
          final animated = Setting().enableAnimations;
      
          return NoteItem(
            note: note,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            elevation: elevation,
            shape: shape,
            animated: animated,
            selecting: isSelecting,
            toggleFinish: homeData.isToggleFinish,
            selected: selected,
            onSelect: (select) => _onNoteSelect(select, note),
            onTap: () => _onNoteTap(note),
            onLongPress: () => _onNoteLongPress(note),
            onDelete: () => _onNoteDelete(note),
            onFinish: () => _onNoteFinish(note),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _blurAnimation,
      builder: (context, child) {
        final double maskOpacity = _blurAnimation.value / 16.0;

        return Stack(
          fit: StackFit.expand,
          children: [
            child!,
            if (maskOpacity > 0)
            Container(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: maskOpacity),
            ),
            if (_blurAnimation.value > 0)
              BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _blurAnimation.value,
                  sigmaY: _blurAnimation.value,
                ),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
          ],
        );
      },
      child: PopScope(
        canPop: !isSelecting,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && isSelecting) {
            setState(() {
              isSelecting = false;
              selectedNotes.clear();
            });
          }
        },
        child: Scaffold(
          extendBodyBehindAppBar: true,
          extendBody: true,
          appBar: const HomeAppBar(),
          drawer: const HomePageDrawer(),
          body: Stack(
            children: [
              IDoAPI.buildAnimatedPadding(
                duration: const Duration(milliseconds: 300),
                padding: isSelecting ? const EdgeInsets.only(top: 40) : EdgeInsets.zero,
                child: _buildBody(),
              ),
              SafeArea(
                child: IDoAPI.buildASWidget(
                  child: isSelecting ? _buildSelectBar() : const SizedBox.shrink(),
                  transitionBuilder: (child, animation) => SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: -1.0,
                    child: child,
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: isSelecting ? null : _buildFloatingActionButton(),
        ),
      ),
    );
  }

  void _onSelectAll() {
    setState(() {
      if (selectedNotes.length == searcher.resultCount) {
        selectedNotes.clear();
      } else  {
        selectedNotes.clear();
        selectedNotes.addAll(searcher.results);
      }
    });
  }

  void _onNoteSelect(bool? select, Note note) {
    setState(() {
      isSelecting = true;
      if (select == true) {
        selectedNotes.add(note);
      } else {
        selectedNotes.remove(note);
      }
    });
  }

  void _onNoteTap(Note note) {
    if (isSelecting) {
      _onNoteSelect(!selectedNotes.contains(note), note);
      return;
    }
    IDoAPI.openEditPage(context, note: note);
  }

  void _onNoteLongPress(Note note) {
    if (isSelecting) return;
    setState(() {
      isSelecting = true;
      selectedNotes.add(note);
    });
  }

  void _onNoteDelete(Note note) async {
    final del = await showDialog(context: context, 
      builder: (context) => AlertDialog(
        title: Text('Are you want to delete "${note.title}"'),
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
            IDoAPI.showSnackBar(context: context, message: 'Delete ${note.title} success');
          }
        },
      );
    }
  }

  void _onNoteFinish(Note note) {
    note.isFinished = !note.isFinished;
    Noter().updateNote(note).then((value) {
      if(value && mounted) {
        setState(() {});
      } 
    });
  }

  void _onNotesDelete() async {
    final del = await showDialog(context: context, 
      builder: (context) => AlertDialog(
        title: Text('Are you want to delete ${selectedNotes.length} notes?'),
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
      Noter().removeNotes(selectedNotes).then((value) {
        if (value) selectedNotes.clear();
        if (value && mounted) {
          IDoAPI.showSnackBar(context: context, message: 'Delete ${selectedNotes.length} notes');
        }
      });
    }
  }
}

class _NoNoteFound extends StatelessWidget {
  const _NoNoteFound();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_alt_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No notes found',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoNoteExist extends StatelessWidget {
  const _NoNoteExist();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_alt_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No notes here ...',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try to create your first note',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
