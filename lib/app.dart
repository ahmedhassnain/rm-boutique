import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_controller.dart';

class RMBoutiqueApp extends StatefulWidget {
  const RMBoutiqueApp({super.key});
  @override
  State<RMBoutiqueApp> createState() => _RMBoutiqueAppState();
}

class _RMBoutiqueAppState extends State<RMBoutiqueApp> {
  late final GoRouter _router = buildRouter(context.read<AuthController>());

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'R&M Boutique',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
