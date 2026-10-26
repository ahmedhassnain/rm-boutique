import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// OWNER: Ahmed (admin). The communication hub from the proposal: one inbox
/// of customer messages tagged "Browsing" or "Ready to order", with one-tap
/// reply templates.
///
/// PLACEHOLDER: the database has no messages table yet, so there is nothing
/// to show. This screen only marks the spot in the navigation. Decide as a
/// team whether to build it or to drop it from the final report.
class InboxTab extends StatelessWidget {
  const InboxTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 48, color: AppColors.olive),
            SizedBox(height: 16),
            Text(
              'Inbox is not built yet',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Planned: customer messages tagged "Browsing" or "Ready to '
              'order", with one-tap reply templates.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
