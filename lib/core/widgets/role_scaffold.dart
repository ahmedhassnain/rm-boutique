import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/auth_controller.dart';

/// Page frame used by every role's screens: app bar with the user's name
/// and a sign-out button.
class RoleScaffold extends StatelessWidget {
  const RoleScaffold({super.key, required this.title, required this.body, this.floatingActionButton});

  final String title;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
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
      body: body,
    );
  }
}
