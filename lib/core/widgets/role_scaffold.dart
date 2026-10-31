import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/auth_controller.dart';

/// Page frame used by every role's screens: app bar with the user's name
/// and a sign-out button. [bottomNavigationBar] is optional so existing
/// single-page roles (admin, customer) are unaffected.
class RoleScaffold extends StatelessWidget {
  const RoleScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.actions = const [],
  });

  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  /// Extra buttons in the app bar, shown before the name and sign-out.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          ...actions,
          if (auth.profile != null)
            Center(child: Text(auth.profile!.fullName, style: const TextStyle(fontSize: 13))),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: auth.signOut,
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: body,
    );
  }
}
