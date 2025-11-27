import 'package:flutter/material.dart';
import 'package:i_do/widgets/scroll_select_wrap.dart';

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
