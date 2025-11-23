import 'package:flutter/material.dart';
import 'package:i_do/data/home_data_.dart';
import 'package:i_do/data/note.dart';
import 'package:i_do/data/searcher.dart';
import 'package:i_do/data/setting.dart';
import 'package:i_do/i_do_api.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isSelecting = false;
  Noter? _noter;
  HomeData? _homeData;
  Searcher? _searcher;
  final List<Note> selectedNotes = [];

  Noter get noter => _noter!;
  HomeData get homeData => _homeData!;
  Searcher get searcher => _searcher!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _noter ??= context.watch<Noter>();
    _searcher ??= context.watch<Searcher>();
    _homeData ??= context.watch<HomeData>();
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
    return Container(
      height: 40,
      color: Colors.transparent,
      child: Row(
        children: [
          SizedBox(width: 8),
          Text('${selectedNotes.length} selected'),
          TextButton(
            onPressed: () {
              setState(() {
                if (selectedNotes.length == searcher.resultCount) {
                  selectedNotes.clear();
                } else  {
                  selectedNotes.clear();
                  selectedNotes.addAll(searcher.results);
                }
              });
            },
            child: Text('Select All'),
          ),
          TextButton(
            onPressed: () async {
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
              if (!del) return;
              Noter().removeNotes(selectedNotes).then((value) {
                if (value && mounted) {
                  IDoAPI.showSnackBar(context: context, message: 'Delete ${selectedNotes.length} notes success');
                }
              });
            },
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
    if (noter.notes.isEmpty) return _buildNoNoteExist();

    final showFinish = homeData.isFinishShown;
    final showUnfinish = homeData.isUnfinishShown;

    // 筛选
    List<Note> notes = searcher.results.where((note) {
      if (note.isFinished && showFinish) return true;
      if (!note.isFinished && showUnfinish) return true;
      return false;
    }).toList();
    switch (homeData.sortMode) {
      case HomeData.SORT_TITLE:
        notes.sort((a, b) => a.title.compareTo(b.title) * (homeData.isSortReverse ? -1 : 1));
      case HomeData.SORT_DATE:
        notes.sort((a, b) => b.dateTime.compareTo(a.dateTime) * (homeData.isSortReverse ? -1 : 1));
      case HomeData.SORT_DEFAULT:
        if (homeData.isSortReverse) {
          notes = notes.reversed.toList();
        }
    }

    selectedNotes.removeWhere((note) => !notes.contains(note));

    if (notes.isEmpty) return _buildNoNoteFound();

    return ListView.builder(
      key: const PageStorageKey('home_note_list'),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return _NoteListItem(
          note: note,
          leadingShown: isSelecting,
          trailingShown: !isSelecting,
          dateShown: homeData.isDateShown,
          tagsShown: homeData.isTagShown,
          toggleFinish: homeData.isToggleFinish,
          selected: selectedNotes.contains(note),
          onSelect: (select) => _onNoteSelect(select, note),
          onTap: () => _onNoteTap(note),
          onLongPress: () => _onNoteLongPress(note),
          onDelete: () => _onNoteDelete(note),
          onFinish: () => _onNoteFinish(note),
        );
      },
    );
  }

  Widget _buildNoNoteExist() {
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

  Widget _buildNoNoteFound() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: const _HAppbar(),
      drawer: const _HDrawer(),
      body: Stack(
        children: [
          IDoAPI.buildAnimatedPadding(
            duration: const Duration(milliseconds: 300),
            padding: isSelecting ? const EdgeInsets.only(top: 40) : EdgeInsets.zero,
            child: _buildBody(),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 56,
            child: IDoAPI.buildASWidget(
              child: isSelecting ? IDoAPI.buildGlassWidget(child: _buildSelectBar()) : const SizedBox.shrink(),
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
    );
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
}

class _HDrawer extends StatefulWidget {
  const _HDrawer();

  @override
  State<_HDrawer> createState() => _HDrawerState();
}

class _HDrawerState extends State<_HDrawer> {
  HomeData? _homeData;
  Setting? _setting;
  HomeData get data => _homeData!;
  Setting get setting => _setting!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _homeData ??= context.watch<HomeData>();
    _setting ??= context.watch<Setting>();
  }

  Widget _buildToolBar() {
    final colorScheme = Theme.of(context).colorScheme; 
    return Row(
      children: [
        // Setting 页
        IconButton(
          color: colorScheme.primary,
          icon: const Icon(Icons.settings),
          onPressed: () {
            IDoAPI.openSettingPage(context);
          },
        ),
        // 切换主题按钮
        IconButton(
          color: colorScheme.primary,
          onPressed: _switchTheme,
          icon: _buildThemeIcon(),
          tooltip: 'Switch Theme',
        ),
      ],
    );
  }

  Widget _buildOptions() {
    final colorScheme = Theme.of(context).colorScheme; 
    final tileTextStyle = TextStyle(color: colorScheme.primary);

    return ExpansionTile(
      key: const PageStorageKey('home_options'),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Options', style: tileTextStyle,),
          const SizedBox(width: 8),
          Icon(Icons.tune),
        ],
      ),
      children: [
        SwitchListTile(
          title: const Text('Floating Edit Button'),
          value: data.isEditButtonFloating,
          onChanged: (value) {
            data.isEditButtonFloating = value;
          },
        ),
        SwitchListTile(
          title: const Text('Show Finished Notes'),
          value: data.isFinishShown,
          onChanged: (value) {
            data.isFinishShown = value;
          },
        ),
        SwitchListTile(
          title: const Text('Show Unfinished Notes'),
          value: data.isUnfinishShown,
          onChanged: (value) {
            data.isUnfinishShown = value;
          },
        ),
        SwitchListTile(
          title: const Text('Show Date'),
          value: data.isDateShown,
          onChanged: (value) {
            data.isDateShown = value;
          },
        ),
        SwitchListTile(
          title: const Text('Show Tags'),
          value: data.isTagShown,
          onChanged: (value) {
            data.isTagShown = value;
          },
        ),
        SwitchListTile(
          title: const Text('Toggle Finish'),
          value: data.isToggleFinish,
          onChanged: (value) {
            data.isToggleFinish = value;
          },
        ),
        SwitchListTile(
          title: const Text('Reverse Sort Order'),
          value: data.isSortReverse,
          onChanged: (value) {
            data.isSortReverse = value;
          },
        ),
      ],
    );
  }

  Widget _buildTagsTile() {
    final colorScheme = Theme.of(context).colorScheme; 
    final tileTextStyle = TextStyle(color: colorScheme.primary);

    return ListTile(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Tags', style: tileTextStyle,),
          const SizedBox(width: 8),
          Icon(Icons.label),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => IDoAPI.openTagsPage(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    
    return Drawer(
      child: ListView(
        key: const PageStorageKey('home_drawer'),
        children: [
          _buildToolBar(),
          _buildOptions(),
          _buildTagsTile(),
        ],
      ),
    );
  }

  Icon _buildThemeIcon() {
    final themeMode = Setting().themeMode;
    final icon = switch (themeMode) {
      ThemeMode.light => Icons.brightness_7,
      ThemeMode.dark => Icons.brightness_4,
      ThemeMode.system => Icons.brightness_auto,
    };
    return Icon(icon);
  }

  void _switchTheme() {
    final themeMode = setting.themeMode;
      switch (themeMode) {
        case ThemeMode.system:
          setting.themeMode = ThemeMode.light;
        case ThemeMode.light:
          setting.themeMode = ThemeMode.dark;
        case ThemeMode.dark:
          setting.themeMode = ThemeMode.system;
      }
  }
}

class _HAppbar extends StatefulWidget implements PreferredSizeWidget {
  const _HAppbar();

  @override
  State<_HAppbar> createState() => _HAppbarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _HAppbarState extends State<_HAppbar> {
  HomeData? _homeData;
  Searcher? _searcher;
  HomeData get data => _homeData!;
  Searcher get searcher => _searcher!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _homeData ??= context.watch<HomeData>();
    _searcher ??= context.watch<Searcher>();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionTheme = theme.appBarTheme.actionsIconTheme?.copyWith(
      color: theme.colorScheme.primary,
    );

    final itemCount = searcher.resultCount;

    return IDoAPI.buildGlassWidget(
      child: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: Colors.transparent,
        title: const Text('I Do'),
        actionsPadding: const EdgeInsets.only(right: 8.0),
        actionsIconTheme: actionTheme,
        actions: [
          // 创建 Note 按钮
          IDoAPI.buildASWidget(
          child: !data.isEditButtonFloating ? IconButton(
              onPressed: _createNote,
              onLongPress: () => data.isEditButtonFloating = true,
              icon: const Icon(Icons.edit),
              tooltip: 'Create Note',
            ) : const SizedBox.shrink(),
          ),
          // 搜索按钮
          IconButton(
            onPressed: _searchNote,
            icon: Badge(
              label: Text(
                '${itemCount < 1000 ? itemCount : '999'}',
              ),
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.8),
              child: const Icon(Icons.search)
            ),
            tooltip: 'Search Note',
          ),
          // 排序按钮
          PopupMenuButton<int>(
            icon: Icon(Icons.sort),
            onSelected: (value) => data.sortMode = value,
            itemBuilder: (context) => [
              const PopupMenuItem<int>(
                value: HomeData.SORT_DEFAULT,
                child: Text('Default'),
              ),
              const PopupMenuItem<int>(
                value: HomeData.SORT_TITLE,
                child: Text('Sort by Title'),
              ),
              const PopupMenuItem<int>(
                value: HomeData.SORT_DATE,
                child: Text('Sort by Date'),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _createNote() {
    IDoAPI.openEditPage(context);
  }

  void _searchNote() {
    IDoAPI.openSearchPage(context);
  }

}

class _NoteListItem extends StatelessWidget {
  const _NoteListItem({
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
    return Row(
      children: [
        Expanded(
          child: Text(
            note.title,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IDoAPI.buildASWidget(
          child: note.isFinished
            ? toggleFinish && trailingShown 
              ? IconButton(key: const ValueKey('check'), onPressed: onFinish, icon: const Icon(Icons.check)) 
              : const Padding(
                key: ValueKey('check'),
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.check),
              )
            : toggleFinish && trailingShown
              ? IconButton(key: const ValueKey('circle'), onPressed: onFinish, icon: const Icon(Icons.circle_outlined)) 
              : const SizedBox(height: 40,),
        ),
      ],
    );
  }

  Widget? _buildSubTitle() {
    return dateShown || tagsShown ? Row(
      children: [
        if (dateShown) Text('${note.dateTime.year}-${note.dateTime.month}-${note.dateTime.day}'),
        if (dateShown) const SizedBox(width: 12),
        if (tagsShown) Expanded(
          child: Text('#${note.tags.join(' #')}',
            overflow: TextOverflow.ellipsis,
          ),
        )
      ],
    ) : null;
  }

  Widget _buildLeading() {
    return IDoAPI.buildASWidget(
      child: leadingShown ? Checkbox(
        value: selected, 
        onChanged: onSelect
      ) : const SizedBox.shrink(),
    );
  }

  Widget _buildTrailing() {
    return IDoAPI.buildASWidget(
      child: trailingShown ? PopupMenuButton<int>(
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
      ) : const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final animated = Setting().enableAnimations;

    return animated ? Stack(
      children: [
        Positioned(
          left: 8,
          top: 0,
          bottom: 0,
          child: _buildLeading(),
        ),
        AnimatedPadding(
          duration: const Duration(milliseconds: 300),
          padding: leadingShown ? const EdgeInsets.only(left: 40.0) : const EdgeInsets.only(right: 30.0),
          child: ListTile(
            title: _bulidTitle(),
            subtitle: _buildSubTitle(),
            selected: selected,
            onTap: onTap,
            onLongPress: onLongPress,
          ),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          right: 12.0,
          child: _buildTrailing(),
        ),
      ],
    ) : ListTile(
      leading: leadingShown ? _buildLeading() : null,
      title: _bulidTitle(),
      subtitle: _buildSubTitle(),
      trailing: trailingShown ? _buildTrailing() : null,
      selected: selected,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}