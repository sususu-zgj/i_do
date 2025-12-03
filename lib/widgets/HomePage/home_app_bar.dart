import 'package:flutter/material.dart';
import 'package:i_do/data/config.dart';
import 'package:i_do/data/searcher.dart';
import 'package:i_do/i_do_api.dart';
import 'package:i_do/widgets/BaseThemeWidget/base_theme_app_bar.dart';
import 'package:provider/provider.dart';

class HomeAppBar extends StatefulWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _HomeAppBarState extends State<HomeAppBar> {
  AppConfig? _homeData;
  Searcher? _searcher;
  AppConfig get data => _homeData!;
  Searcher get searcher => _searcher!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _homeData ??= context.watch<AppConfig>();
    _searcher ??= context.watch<Searcher>();
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = searcher.resultCount;
    final columnCount = data.columnsCount;
    final theme = Theme.of(context);

    return BaseAppBar(
      title: const Text('I Do'),
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
              value: AppConfig.SORT_DEFAULT,
              child: Text('Default'),
            ),
            const PopupMenuItem<int>(
              value: AppConfig.SORT_TITLE,
              child: Text('Sort by Title'),
            ),
            const PopupMenuItem<int>(
              value: AppConfig.SORT_DATE,
              child: Text('Sort by Date'),
            ),
            const PopupMenuItem<int>(
              value: AppConfig.SORT_STARRED,
              child: Text('Sort by Starred'),
            ),
          ],
        ),
        IDoAPI.buildASWidget(
          child: IconButton(
            key: columnCount == 1 ? const ValueKey('view_agenda') : const ValueKey('grid_view'),
            icon: columnCount == 1 ? const Icon(Icons.view_agenda) : const Icon(Icons.grid_view_rounded),
            onPressed: () {
              data.columnsCount = columnCount == 1 ? 2 : 1;
            },
          ),
        )
      ],
    );
  }

  void _createNote() {
    IDoAPI.openEditPage(context);
  }

  void _searchNote() {
    IDoAPI.openSearchPage(context);
  }

}
