import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// One of the two summary blocks under the filter buttons: a big number on
/// top and a short grey label below. Tap it to jump to the matching list.
class SummaryTile extends StatelessWidget {
  const SummaryTile({
    super.key,
    required this.value,
    required this.label,
    this.onTap,
    this.warn = false,
  });

  final String value;
  final String label;
  final VoidCallback? onTap;

  /// Colours the number terracotta (something needs attention).
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.sand, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 88,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: warn ? AppColors.terracotta : AppColors.olive,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
