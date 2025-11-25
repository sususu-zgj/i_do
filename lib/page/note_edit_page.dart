import 'dart:async';

import 'package:flutter/material.dart';
import 'package:i_do/data/edit_data.dart';
import 'package:i_do/data/note.dart';
import 'package:i_do/data/searcher.dart';
import 'package:i_do/data/setting.dart';
import 'package:i_do/i_do_api.dart';
import 'package:i_do/widgets/base_theme_widget.dart';
import 'package:i_do/widgets/scroll_select_wrap.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class NoteEditPage extends StatefulWidget {
  const NoteEditPage({super.key});

  @override
  State<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends State<NoteEditPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  final _formKey = GlobalKey<FormState>();

  EditData? _editData;
  late final TextEditingController _titleController;
  late final TextEditingController _textController;

  late DateTime _dateTime;
  late bool _finish;

  Note? get note => _editData!.note;
  List<String> get _tags => _editData!.tags;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_editData != null) return;
    _editData = context.watch<EditData>();
    _dateTime = note?.dateTime ?? DateTime.now();
    _finish = note?.isFinished ?? false;
    _titleController = TextEditingController(text: note?.title ?? '');
    _textController = TextEditingController(text: note?.text ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }
  
  PreferredSizeWidget _buildAppBar() {
    final borderColor = Theme.of(context).colorScheme.primary;

    return BaseAppBar(
      title: const Text('Edit'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _finish = !_finish;
            });
          },
          child: IDoAPI.buildASWidget(
            child: _finish ? const Text('  Finish  ', key: ValueKey('Edit-Page-Finish'),) : const Text('Unfinish', key: ValueKey('Edit-Page-Unfinish'),),
            duration: const Duration(milliseconds: 400)
          ),
        ),
        SizedBox(height: 24, child: VerticalDivider(width: 1, color: borderColor,)),
        TextButton(
          onPressed: _selectTime,
          child: Row( 
            children: [
              Icon(Icons.edit_calendar),
              SizedBox(width: 8,),
              Text('${_dateTime.year}-${_dateTime.month}-${_dateTime.day}'),
            ],
          ) 
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Card(
      elevation: IDoAPI.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(  // Title
                decoration: const InputDecoration(
                  labelText: 'Title',
                ),
                controller: _titleController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0,),
              Expanded(   // Text
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Text',
                    border: InputBorder.none,
                    floatingLabelBehavior: FloatingLabelBehavior.always
                  ),
                  controller: _textController,
                  textAlignVertical: TextAlignVertical.top,
                  minLines: null,
                  maxLines: null,
                  expands: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottom() {
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: IDoAPI.cardElevation,
            child: TextButton(
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              child: Text(
                _tags.isNotEmpty ? 'Tags: #${_tags.join(' #')}' : 'Add Tag',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              )
            ),
          ),
        ),
        Card(
          elevation: IDoAPI.cardElevation,
          child: TextButton(
            onPressed: _saveNote, 
            child: const Text('Save')
          ),
        )
      ],
    );
  }

  Widget _buildDrawer() {
    return _EDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(child: _buildBody()),
            _buildBottom(),
          ],
        ),
      )
    );
  }

  void _selectTime() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _dateTime) {
      setState(() {
        _dateTime = picked;
      });
    }
  }

  void _saveNote() async {
    final valid = _formKey.currentState?.validate();
    if (valid == true) {
      final title = _titleController.text.trim();

      if (note == null) {
        Note newNote = Note(
          title: title,
          text: _textController.text,
          tags: _tags,
          date: _dateTime,
          isFinished: _finish,
        );
        Noter().addNote(newNote).then((value) {if(value) Searcher().search();});
      }
      else {
        note!.title = title;
        note!.text = _textController.text;
        note!.tags = _tags;
        note!.dateTime = _dateTime;
        note!.isFinished = _finish;
        Noter().updateNote(note!).then((value) {if(value) Searcher().search();});
      }
      
      IDoAPI.showSnackBar(
        context: context, 
        message: '$title saved',
      );
      if (note == null || Setting().savePop) Navigator.of(context).pop();
    }
    else {
      IDoAPI.showSnackBar(
        context: context, 
        message: 'Title cannot be empty',
      );
    }
  }
}

class TagCreateDialog extends StatefulWidget {
  const TagCreateDialog({super.key, this.onCreate});

  final void Function(List<String> tags)? onCreate;

  @override
  State<TagCreateDialog> createState() => _TagCreateDialogState();
}

class _TagCreateDialogState extends State<TagCreateDialog> {
  List<String> _tags = [];
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _textFieled() {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: 'Tag name',
        helperText: 'You can use "#" to separate multiple tags',
        helperMaxLines: 2,
        border: OutlineInputBorder()
      ),
      onChanged: (value) => setState(() {
        final ts = value.split('#').where(
          (tag) {
            return tag.trim().isNotEmpty;
          }
        );
        _tags = ts.map((tag) => tag.trim()).toSet().toList();
      }),
    );
  }

  Widget _content() {
    return ScrollSelectWrap(
      items: _tags,
      isSelected: (_) => true,
      itemLabel: (item) => item,
      spacing: 8.0,
      runSpacing: 8.0,
      onSelected: (value) {
        setState(() {
          _tags.remove(value);
          _controller.text = _tags.join('#');
        });
      },
    );
  }

  List<Widget> _actions() {
    return [
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: Text('Cancel'),
      ),
      TextButton(
        onPressed: () {
          widget.onCreate?.call(_tags);
          Navigator.of(context).pop();
        },
        child: Text('Create'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: _textFieled(),
      content: _content(),
      actions: _actions()
    );
  }
}

class _EDrawer extends StatefulWidget {
  @override
  State<_EDrawer> createState() => _EDrawerState();
}

class _EDrawerState extends State<_EDrawer> {
  EditData? editData;
  Timer? _debounceTimer;
  TextEditingController? _searchController;
  int _selectedSegment = 0; // 0: 已选择, 1: 所有标签
  int crossAxisCount = 2;

  String get _searchQuery => _searchController?.text ?? '';

  List<String> get _tags => editData!.tags;
  List<String> get _tagSource => editData!.allTags;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    editData ??= context.watch<EditData>();
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Title
        Row(
          children: [
            Text('Select tags or', style: Theme.of(context).textTheme.titleLarge),
            TextButton(
              onPressed: _createTag,
              child: Text(
                'Write',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 分段按钮
        SegmentedButton<int>(
          segments: [
            ButtonSegment<int>(
              value: 0,
              label: Text('Selected (${_tags.length})'),
              icon: const Icon(Icons.check_circle),
            ),
            ButtonSegment<int>(
              value: 1,
              label: Text('All (${_tagSource.length})'),
              icon: const Icon(Icons.label),
            ),
          ],
          selected: {_selectedSegment},
          onSelectionChanged: (selection) {
            setState(() {
              _selectedSegment = selection.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSelectedTags() {
    // Empty
    if (_tags.isEmpty) {
      return _buildNoTagSelected();
    }

    final colorScheme = Theme.of(context).colorScheme;
    // Selected tags
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 4.0,
        runSpacing: 4.0,
        children: _tags.map((tag) => 
          Chip(
            label: Text(tag),
            labelStyle: TextStyle(
              color: colorScheme.onPrimaryContainer,
            ),
            deleteIconColor: colorScheme.onPrimaryContainer,
            backgroundColor: colorScheme.primaryContainer,
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () => _selectTag(tag),
          ),
        ).toList(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0,),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tags...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController?.clear();
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
          IconButton(
            icon: crossAxisCount == 1 ? const Icon(Icons.view_agenda) : const Icon(Icons.grid_view),
            onPressed: () {
              setState(() {
                crossAxisCount = crossAxisCount == 1 ? 2 : 1;
              });
            },
          )
        ],
      ),
    );
  }

  Widget _buildAllTags() {
    if (_tagSource.isEmpty) {
      return _buildNoTagExist();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0),);
    final selectedColor = colorScheme.primary;
    final onSelectedColor = colorScheme.onPrimary;

    return Column(
      children: [
        _buildSearchBar(),
        const SizedBox(height: 8),
        Expanded(
          child: _filteredTags.isEmpty
          ? _buildNoTagExist()
          : MasonryGridView.count(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 4.0,
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemCount: _filteredTags.length,
            itemBuilder: (context, index) {
              final tag = _filteredTags[index];
              final isSelected = _tags.contains(tag);

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
                  trailing: isSelected && crossAxisCount == 1
                      ? Icon(Icons.check, color: onSelectedColor,)
                      : null,
                  onTap: () => _selectTag(tag),
                  shape: shape,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Card(
      elevation: IDoAPI.cardElevation,
      child: _selectedSegment == 0
        ? _buildSelectedTags()
        : _buildAllTags(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            Expanded(child: SizedBox.expand(child: _buildContent())),
          ],
        ),
      ),
    );
  }

  void _selectTag(String tag) {
    setState(() {
      if (_tags.contains(tag)) {
        _tags.remove(tag);
      } else {
        _tags.add(tag);
      }
    });

    Future.microtask(() => editData?.update());
  }

  void _createTag() {
    showDialog(
      context: context,
      builder: (context) => TagCreateDialog(onCreate: (tags) {
        setState(() {
          for (var tag in tags) {
            if (!_tags.contains(tag)) {
              _tags.add(tag);
            }
            if (!_tagSource.contains(tag)) {
              _tagSource.add(tag);
            }
          }
        });
        editData!.update();
      }),
    );
  }

  List<String> get _filteredTags {
    return _tagSource.where((tag) =>
      tag.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  Widget _buildNoTagExist() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_circle_outline,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No tags available',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Write" to create new tags',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoTagSelected() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.label_outline,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No tags selected',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Switch to "All" to select tags',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}