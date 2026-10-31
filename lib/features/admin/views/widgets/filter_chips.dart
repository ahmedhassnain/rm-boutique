import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Single-choice filter buttons (the four "Header" buttons of the wireframe).
/// Generic on purpose: the Orders, Payments and Inventory screens all use it,
/// each with its own enum of options.
/// [twoColumns] lays them out as a 2 x 2 grid like the wireframe; otherwise
/// they sit in one row that scrolls sideways on narrow phones.
class FilterChips<T> extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.twoColumns = false,
  });

  final List<T> options;
  final T selected;
  final String Function(T option) labelOf;
  final void Function(T option) onSelected;
  final bool twoColumns;

  /// A rounded button as wide as its cell (used for the 2 x 2 grid).
  Widget _wideButton(T option) {
    final isSelected = option == selected;
    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected ? AppColors.ink : Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: StadiumBorder(
          side: BorderSide(
              color: isSelected ? AppColors.ink : AppColors.hairline),
        ),
        child: InkWell(
          onTap: () => onSelected(option),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Center(
              child: Text(
                labelOf(option),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.slate,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(T option) => ChoiceChip(
        label: Text(labelOf(option)),
        selected: option == selected,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          color: option == selected ? Colors.white : AppColors.slate,
        ),
        showCheckmark: false,
        selectedColor: AppColors.ink,
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.hairline),
        shape: const StadiumBorder(),
        onSelected: (_) => onSelected(option),
      );

  @override
  Widget build(BuildContext context) {
    if (twoColumns) {
      return LayoutBuilder(
        builder: (context, constraints) {
          const gap = 12.0;
          final width = (constraints.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap,
            runSpacing: 10,
            children: [
              for (final option in options)
                SizedBox(width: width, child: _wideButton(option)),
            ],
          );
        },
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _chip(option),
            ),
        ],
      ),
    );
  }
}
