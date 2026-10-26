import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// A row of single-choice chips (the "Category 1..4" row in the wireframe).
/// Generic on purpose: the Orders, Payments and Inventory screens all use it,
/// each with its own enum of options. Scrolls sideways on narrow phones.
class FilterChips<T> extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final List<T> options;
  final T selected;
  final String Function(T option) labelOf;
  final void Function(T option) onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                label: Text(labelOf(option)),
                selected: option == selected,
                showCheckmark: false,
                selectedColor: AppColors.sand,
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.charcoal),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onSelected: (_) => onSelected(option),
              ),
            ),
        ],
      ),
    );
  }
}
