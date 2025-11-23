import 'package:flutter/material.dart';
import 'package:i_do/data/note.dart';
import 'package:i_do/i_do_api.dart';
import 'package:i_do/page/note_edit_page.dart';
import 'package:provider/provider.dart';

class TagsPage extends StatefulWidget {
  const TagsPage({super.key});

  @override
  State<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends State<TagsPage> {

  final Set<String> _selectedTags = {};
  bool _isSelectionMode = false;

  void _toggleSelection(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
      _isSelectionMode = _selectedTags.isNotEmpty;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedTags.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _showCreateDialog() async {
    final noter = context.read<Noter>();
    showDialog(
      context: context,
      builder: (context) => TagCreateDialog(onCreate: (tags) {
        noter.addTags(tags).then(
          (value) {
            if (value && mounted) {
              IDoAPI.showSnackBar(
                context: context,
                message: 'Added ${tags.length} tag(s)',
                duration: const Duration(milliseconds: 800),
              );
            }
          }
        );
      }),
    );
  }

  Future<void> _deleteSelectedTags() async {
    if (_selectedTags.isEmpty) return;
    final noter = Noter();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tags'),
        content: Text(
          'Are you sure you want to delete ${_selectedTags.length} tag(s)?\n'
          'This will remove these tags from all notes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await noter.removeTags(_selectedTags.toList());
      if (success && mounted) {
        IDoAPI.showSnackBar(
          context: context,
          message: 'Deleted ${_selectedTags.length} tag(s)',
        );
        _clearSelection();
      }
    }
  }

  Future<void> _deleteTag(String tag) async {
    final noter = Noter();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tag'),
        content: Text(
          'Are you sure you want to delete the tag "#$tag"?\n'
          'This will remove this tag from all notes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await noter.removeTag(tag);
      if (success && mounted) {
        IDoAPI.showSnackBar(
          context: context,
          message: 'Deleted tag "#$tag"',
          duration: const Duration(milliseconds: 800),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _isSelectionMode ? null : _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_isSelectionMode ? '${_selectedTags.length} selected' : 'Manage Tags'),
      leading: _isSelectionMode
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearSelection,
            )
          : IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
      actions: _isSelectionMode
          ? [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deleteSelectedTags,
                tooltip: 'Delete selected',
              ),
            ]
          : null,
    );
  }

  Widget _buildBody() {
    final noter = context.watch<Noter>();
    final tags = noter.tags;
    if (tags.isEmpty) {
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
              'No tags yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to create your first tag',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: tags.length,
      itemBuilder: (context, index) {
        final tag = tags[index];
        final isSelected = _selectedTags.contains(tag);

        return Card(
          elevation: isSelected ? 4 : 1,
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          child: ListTile(
            leading: _isSelectionMode
                ? Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(tag),
                  )
                : Icon(
                    Icons.label,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            title: Text(
              '#$tag',
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected 
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : null,
              ),
            ),
            trailing: _isSelectionMode
                ? null
                : IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () => _deleteTag(tag),
                  ),
            onTap: () => _toggleSelection(tag),
            onLongPress: () => _toggleSelection(tag),
          ),
        );
      },
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _showCreateDialog,
      tooltip: 'Add tag',
      child: const Icon(Icons.add),
    );
  }
}