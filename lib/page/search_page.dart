import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:i_do/data/note.dart';
import 'package:i_do/data/searcher.dart';
import 'package:i_do/widgets/base_theme_widget.dart';
import 'package:i_do/widgets/scroll_select_wrap.dart';

///
/// 搜索页
///
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // 搜索选项
  List<String> _allTags = [];
  final TextEditingController _titleController = TextEditingController();
  String title = '';
  List<String> tags = [];
  late int year;
  late int month;
  late int day;
  List<String> blackTags = [];
  bool titleStrict = false;
  bool tagStrict = false;

  final double elevation = 4;

  // 从上次搜索初始化选项
  @override
  void initState() {
    super.initState();
    _allTags = Noter().tags;
    final f = Searcher();
    
    year = f.year;
    month = f.month;
    day = f.day;
    title = f.title;
    _titleController.text = title;
    tags = List.of(f.tags);
    blackTags = List.of(f.blackTags);
    titleStrict = f.titleStrict;
    tagStrict = f.tagStrict;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  PreferredSizeWidget _appBar() {
    return BaseAppBar(
      title: TextField(
        controller: _titleController,
        decoration: const InputDecoration(
          labelText: 'Search Title',
          hintText: 'Enter note title...',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          title = value;
        },
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            onPressed: _search,
            icon: Icon(Icons.search),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // 包含搜索选项及日期选择
  Widget _buildSearchOption() {
    return Card(
      elevation: elevation,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._searchOptions(),
            Divider(height: 16),
            ..._dateSelector(),
          ],
        ),
      ),
    );
  }

  // 标签选择器
  Widget _buildTagSelector() {
    return _buildSelectedTags(
      tags: tags, 
      onSelected: (selectedTags) {
        setState(() {
          tags = selectedTags;
          for (final t in tags) {
            if (blackTags.contains(t)) {
              blackTags.remove(t);
            }
          }
        });
      }, 
      onTap: _tapIncludeTag, 
      padding: const EdgeInsets.fromLTRB(12, 12, 0, 12), 
      titlePadding: const EdgeInsets.fromLTRB(12, 12, 0, 0),
      title: 'Include Tags', 
      icon: Icons.label, 
      trailingColor: Theme.of(context).primaryColor
    );
  }

  // 标签黑名单选择器
  Widget _buildBlackTagSelector() {
    return _buildSelectedTags(
      tags: blackTags, 
      onSelected: (selectedTags) {
        setState(() {
          blackTags = selectedTags;
          for (final t in blackTags) {
            if (tags.contains(t)) {
              tags.remove(t);
            }
          }
        });
      }, 
      onTap: _tapExcludeTag, 
      padding: const EdgeInsets.fromLTRB(0, 12, 12, 12), 
      titlePadding: const EdgeInsets.fromLTRB(0, 12, 12, 0),
      title: 'Exclude Tags', 
      icon: Icons.block, 
      trailingColor: Colors.red
    );
  }

  Widget _buildNoTagSelected({required void Function(List<String> selectedTags) onSelected, List<String> selectedTags = const []}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.label_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No tags selected',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final selected = await showDialog<List<String>>(
                context: context,
                builder: (context) {
                  return SelectTagDialog(
                    allTags: _allTags,
                    selectedTags: selectedTags,
                  );
                },
              );
              if (selected != null && selected.isNotEmpty) {
                onSelected(selected);
              }
            },
            icon: Icon(Icons.add),
            label: Text('Select Tags'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTags({
    required List<String> tags, 
    required void Function(List<String> selectedTags) onSelected,
    required void Function(String tag) onTap,
    required EdgeInsetsGeometry titlePadding,
    required EdgeInsetsGeometry padding, 
    required String title, 
    required IconData icon, 
    required Color trailingColor
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // title
        Padding(
          padding: titlePadding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20),
                  SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: trailingColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${tags.length}',
                      style: TextStyle(
                        color: trailingColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (tags.isNotEmpty)
                Row(
                  children: [
                    TextButton(
                      onPressed: () async {
                        final selected = await showDialog<List<String>>(
                          context: context,
                          builder: (context) {
                            return SelectTagDialog(
                              allTags: _allTags,
                              selectedTags: tags,
                            );
                          },
                        );
                        if (selected != null && selected.isNotEmpty) {
                          onSelected(selected);
                        }
                      },
                      child: Icon(Icons.add, size: 18),
                    ),
                    SizedBox(
                      height: 20,
                      child: VerticalDivider(
                        width: 0,
                        thickness: 1,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          tags.clear();
                        });
                      },
                      child: Icon(Icons.clear, size: 18),
                    ),
                  ],
                )
            ],
          ),
        ),
        // tag wrap
        Expanded(
          child: Padding(
            padding: padding,
            child: tags.isEmpty 
            ? _buildNoTagSelected(onSelected: onSelected, selectedTags: tags) 
            : ScrollSelectWrap<String>(
              isSelected: (item) => tags.contains(item),
              itemLabel: (item) => item,
              items: tags,
              sortWithSelect: true,
              onSelected: onTap,
            ),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSearchOption(),
            SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Card(
                  elevation: elevation,
                  child: Row(
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 64,
                        child: _buildTagSelector(),
                      ),
                      VerticalDivider(
                        width: 8, 
                        thickness: 1, 
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 64,
                        child: _buildBlackTagSelector(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 搜索回调
  void _search() {
    final filter = SearchFilter(
      id: '',
      title: title.trim(),
      tags: tags,
      blackTags: blackTags,
      year: year,
      month: month,
      day: day,
      titleStrict: titleStrict,
      tagStrict: tagStrict,
    );
    Searcher().byFilter(null, filter);
    Navigator.pop(context);
  }

  // 搜索选项
  List<Widget> _searchOptions() {
    return [
      // 选项标题栏
      Row(
        children: [
          Icon(Icons.tune, size: 20),
          SizedBox(width: 8),
          Text(
            'Search Options',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: CheckboxListTile(
              title: Text('Strict Title Match'),
              subtitle: Text('Exact title matching', style: TextStyle(fontSize: 12)),
              value: titleStrict,
              onChanged: (value) {
                setState(() {
                  titleStrict = value ?? false;
                });
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: CheckboxListTile(
              title: Text('Strict Tag Match'),
              subtitle: Text('Must include all tags', style: TextStyle(fontSize: 12)),
              value: tagStrict,
              onChanged: (value) {
                setState(() {
                  tagStrict = value ?? false;
                });
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        ],
      ),
    ];
  }

  // 日期选择器
  List<Widget> _dateSelector() {
    final years = Noter().dateTimes.map((e) => e.year).toSet().toList()
      ..sort((a, b) => a.compareTo(b));
    final months = [for (int i = 1; i <= 12; i++) i];
    final days = [for (int i = 1; i <= 31; i++) i];

    return [
      // 日期选择标题栏
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, size: 20),
              SizedBox(width: 8),
              Text(
                'Date Filter',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {
                  DateTime now = DateTime.now();
                  setState(() {
                    year = now.year;
                    month = now.month;
                    day = now.day;
                  });
                },
                child: Text('Today'),
              ) 
            ],
          ),
          if (year != -1 || month != -1 || day != -1)
            SizedBox(
              height: 24,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    year = month = day = -1;
                  });
                },
                icon: Icon(Icons.clear, size: 18),
                label: Text('Clear'),
              ),
            ),
        ],
      ),
      SizedBox(height: 12),
      // 日期选择器
      Row(
        children: [
          // year
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: years.contains(year) ? year : -1,
              decoration: InputDecoration(
                labelText: 'Year',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [-1, ...years].map((e) {
                return DropdownMenuItem<int>(
                  value: e,
                  child: Text(e > 0 ? e.toString() : 'Any',),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  year = value ?? -1;
                  if (year == -1) {
                    month = -1;
                    day = -1;
                  }
                });
              },
            ),
          ),
          SizedBox(width: 8),
          // month
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: months.contains(month) ? month : -1,
              decoration: InputDecoration(
                labelText: 'Month',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [-1, ...months].map((e) {
                  return DropdownMenuItem<int>(
                    value: e,
                    child: Text(e > 0 ? e.toString() : 'Any'),
                  );
                }).toList(),
              onChanged: year == -1 ? null : (value) {
                setState(() {
                  month = value ?? -1;
                  if (month == -1) {
                    day = -1;
                  }
                });
              },
            ),
          ),
          SizedBox(width: 8),
          // day
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: days.contains(day) ? day : -1,
              decoration: InputDecoration(
                labelText: 'Day',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [-1, ...days].map((e) {
                  return DropdownMenuItem<int>(
                    value: e,
                    child: Text(e > 0 ? e.toString() : 'Any'),
                  );
                }).toList(),
              onChanged: year == -1 || month == -1 ? null : (value) {
                setState(() {
                  day = value ?? -1;
                });
              },
            ),
          ),
        ],
      ),
    ];
  }

  void _tapIncludeTag(String tag) {
    setState(() {
      tags.remove(tag);
    });
  }

  void _tapExcludeTag(String tag) {
    setState(() {
      blackTags.remove(tag);
    });
  }

}

class SelectTagDialog extends StatefulWidget {
  final List<String> allTags;
  final List<String> selectedTags;

  const SelectTagDialog({
    super.key,
    required this.allTags,
    required this.selectedTags,
  });

  @override
  State<SelectTagDialog> createState() => _SelectTagDialogState();
}

class _SelectTagDialogState extends State<SelectTagDialog> {
  late List<String> _tempSelectedTags;
  late TextEditingController _searchController;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _tempSelectedTags = List.of(widget.selectedTags);
  }

  Widget _buildSearcher() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tags...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                _debounceTimer?.cancel();
                _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                  setState(() {
                  });
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagGrid() {
    final searchText = _searchController.text.trim().toLowerCase();
    final filteredTags = widget.allTags.where((tag) => tag.toLowerCase().contains(searchText)).toList();

    if (filteredTags.isEmpty) {
      return _buildNoTagFound();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0),);
    final selectedColor = colorScheme.primary;
    final onSelectedColor = colorScheme.onPrimary;

    return MasonryGridView.count(
      crossAxisCount: 2,
      itemCount: filteredTags.length,
      mainAxisSpacing: 4.0,
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      itemBuilder: (context, index) {
        final tag = filteredTags[index];
        final isSelected = _tempSelectedTags.contains(tag);

        return Card(
          color: isSelected ? selectedColor : null,
          elevation: isSelected ? 8 : 2,
          shape: shape.copyWith(side: BorderSide(color: Colors.transparent, width: 1.2)),
          child: ListTile(
            title: Text(
              tag,
              style: TextStyle(
                color: isSelected
                    ? onSelectedColor
                    : null,
              ),
            ),
            onTap: () {
              setState(() {
                if (isSelected) {
                  _tempSelectedTags.remove(tag);
                } else {
                  _tempSelectedTags.add(tag);
                }
              });
            },
            shape: shape,
          ),
        );
      },
    );
  }

  Widget _buildNoTagFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.label_off,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          Text(
            'No tags found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select Tags'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          children: [
            _buildSearcher(),
            Expanded(
              child: _buildTagGrid(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, _tempSelectedTags);
          },
          child: Text('OK'),
        ),
      ],
    );
  }
}
