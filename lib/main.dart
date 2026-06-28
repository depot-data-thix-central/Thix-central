import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thix_central/nav.dart';
import 'package:thix_central/theme.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';

/// Main entry point for the application
///
/// This sets up:
/// - go_router navigation
/// - Material 3 theming with light/dark modes
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // IMPORTANT (Publish/Web): never block the first Flutter frame on network/config
  // initialization. If initialization hangs, the published link stays on
  // "Loading ..." forever.
  //
  // We initialize Supabase asynchronously after runApp, and the splash screen
  // will await it (with a timeout) before deciding where to route.
  unawaited(SupabaseClientProvider.initializeFromEnv());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // As you extend the app, use MultiProvider to wrap the app
    // and provide state to all widgets
    // Example:
    // return MultiProvider(
    //   providers: [
    //     ChangeNotifierProvider(create: (_) => ExampleProvider()),
    //   ],
    //   child: MaterialApp.router(
    //     title: 'Dreamflow Starter',
    //     debugShowCheckedModeBanner: false,
    //     routerConfig: AppRouter.router,
    //   ),
    // );
    return ProviderScope(
      child: MaterialApp.router(
        title: 'THIX CENTRAL',
        debugShowCheckedModeBanner: false,

        // Theme configuration
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,

        // Router configuration
        routerConfig: AppRouter.router,
      ),
    );
  }
}
