import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'features/auth/auth_controller.dart';
import 'features/customer/viewmodels/cart_viewmodel.dart';
import 'shared/repositories/message_repository.dart';
import 'shared/repositories/order_repository.dart';
import 'shared/repositories/product_repository.dart';
import 'shared/repositories/storage_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Needs a ".env" file (copy .env.example). See README.
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
  url: dotenv.env['SUPABASE_URL']!,
  publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        // Repositories: get them in any screen or view-model with
        //   context.read<OrderRepository>()
        // The customer's basket lives for the whole app and empties itself
        // when a different person signs in.
        ChangeNotifierProxyProvider<AuthController, CartViewModel>(
          create: (_) => CartViewModel(),
          update: (_, auth, cart) => (cart ?? CartViewModel())
            ..bindTo(auth.profile?.id),
        ),
        Provider(create: (_) => OrderRepository()),
        Provider(create: (_) => MessageRepository()),
        Provider(create: (_) => ProductRepository()),
        Provider(create: (_) => StorageRepository()),
      ],
      child: const RMBoutiqueApp(),
    ),
  );
}
