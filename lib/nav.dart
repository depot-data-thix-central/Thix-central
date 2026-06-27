import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_central/auth/thix_login_page.dart';
import 'package:thix_central/market/pages/market_cart_page.dart';
import 'package:thix_central/market/pages/market_home_page.dart';
import 'package:thix_central/market/pages/market_orders_page.dart';
import 'package:thix_central/market/pages/market_product_detail_page.dart';
import 'package:thix_central/pages/app_shell/app_shell.dart';
import 'package:thix_central/pages/home/thix_home_page.dart';
import 'package:thix_central/pages/messages/messages_page.dart';
import 'package:thix_central/pages/profile/profile_page.dart';
import 'package:thix_central/pages/scan/thix_scan_page.dart';
import 'package:thix_central/pages/services/services_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) {
          final next = state.uri.queryParameters['next'];
          return NoTransitionPage(child: ThixLoginPage(afterLoginRoute: next));
        },
      ),
      GoRoute(
        path: AppRoutes.market,
        name: 'market',
        pageBuilder: (context, state) => const MaterialPage(child: MarketHomePage()),
        routes: [
          GoRoute(path: 'cart', name: 'market_cart', pageBuilder: (context, state) => const MaterialPage(child: MarketCartPage())),
          GoRoute(path: 'orders', name: 'market_orders', pageBuilder: (context, state) => const MaterialPage(child: MarketOrdersPage())),
          GoRoute(
            path: 'product/:id',
            name: 'market_product',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return MaterialPage(child: MarketProductDetailPage(productId: id));
            },
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: AppRoutes.home, name: 'home', pageBuilder: (context, state) => const NoTransitionPage(child: ThixHomePage())),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: AppRoutes.services, name: 'services', pageBuilder: (context, state) => const NoTransitionPage(child: ServicesPage())),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: AppRoutes.scan, name: 'scan', pageBuilder: (context, state) => const NoTransitionPage(child: ThixScanPage())),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: AppRoutes.messages, name: 'messages', pageBuilder: (context, state) => const NoTransitionPage(child: MessagesPage())),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: AppRoutes.profile, name: 'profile', pageBuilder: (context, state) => const NoTransitionPage(child: ProfilePage())),
            ],
          ),
        ],
      ),
    ],
  );
}

class AppRoutes {
  static const String home = '/';
  static const String services = '/services';
  static const String scan = '/scan';
  static const String messages = '/messages';
  static const String profile = '/profile';
  static const String market = '/market';
  static const String login = '/login';
}
