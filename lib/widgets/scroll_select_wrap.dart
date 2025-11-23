import 'package:flutter/material.dart';

class ScrollWrap extends StatelessWidget {
  const ScrollWrap({
    super.key, 
    this.spacing = 8.0, 
    this.runSpacing = 8.0, 
    this.direction = Axis.horizontal, 
    required this.children,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final Axis direction;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: super.key,
      child: Wrap(
        spacing: spacing,
        direction: direction,
        runSpacing: runSpacing,
        children: children
      ),
    );
  }
}

class ScrollSelectWrap<T> extends StatelessWidget {
  const ScrollSelectWrap({
    super.key, 
    this.sortWithSelect = false, 
    this.reversed = false,
    this.showCheckmark = false,
    this.onSelected,
    this.enabled,
    required this.isSelected,
    required this.itemLabel,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.direction = Axis.horizontal,
    required this.items,
    this.selectedColor,
  });

  final double spacing;
  final double runSpacing;
  final Axis direction;

  // 数据源
  final List<T> items;
  final bool sortWithSelect;
  final bool reversed;
  final bool showCheckmark;
  final Color? selectedColor;

  final Function(T item)? onSelected;
  final bool Function(T item) isSelected;
  final bool Function(T item)? enabled;
  final String Function(T item) itemLabel;

  List<Widget> _buildChildren(BuildContext context) {
    final its = List<T>.from(items);
    
    // 如果需要排序选中项
    if (sortWithSelect) {
      its.sort((a, b) {
        final aSelected = isSelected(a);
        final bSelected = isSelected(b);
        // 选中的排在前面，未选中的排在后面
        return (bSelected ? 1 : 0) - (aSelected ? 1 : 0);
      });
    }
    
    // 如果需要反转
    if (reversed) {
      its.sort((a, b) {
        final aSelected = isSelected(a);
        final bSelected = isSelected(b);
        // 未选中的排在前面，选中的排在后面
        return (aSelected ? 1 : 0) - (bSelected ? 1 : 0);
      });
    }
    
    // 创建widget
    return its.map((item) => _createItem(
      item, 
      isSelected(item),
      selectedColor ?? Theme.of(context).colorScheme.primaryContainer
    )).toList();
  }

  Widget _createItem(T item, bool selected, Color selectedColor) {
    return ChoiceChip(
      showCheckmark: showCheckmark,
      label: Text(itemLabel(item)),
      selected: selected,
      //selectedColor: selectedColor,
      onSelected: enabled == null || enabled!.call(item) ? (_) {
        onSelected?.call(item);
      } : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = _buildChildren(context);
    
    return ScrollWrap(
      spacing: spacing,
      runSpacing: runSpacing,
      direction: direction,
      children: children,
    );
  }
}