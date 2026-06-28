import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_central/auth/thix_login_page.dart';
import 'package:thix_central/auth/thix_otp_verify_page.dart';
import 'package:thix_central/auth/thix_signup_page.dart';
import 'package:thix_central/auth/thix_splash_page.dart';
import 'package:thix_central/auth/thix_identity_card_page.dart';
import 'package:thix_central/market/pages/market_cart_page.dart';
import 'package:thix_central/market/pages/market_home_page.dart';
import 'package:thix_central/market/pages/market_orders_page.dart';
import 'package:thix_central/market/pages/market_product_detail_page.dart';
import 'package:thix_central/market/pages/market_sell_page.dart';
import 'package:thix_central/pages/app_shell/app_shell.dart';
import 'package:thix_central/pages/home/thix_home_page.dart';
import 'package:thix_central/pages/messages/messages_page.dart';
import 'package:thix_central/pages/news/news_home_page.dart';
import 'package:thix_central/pages/profile/profile_page.dart';
import 'package:thix_central/pages/reservation/reservation_home_page.dart';
import 'package:thix_central/pages/scan/thix_scan_page.dart';
import 'package:thix_central/pages/services/services_page.dart';
import 'package:thix_central/pages/events/event_detail_page.dart';
import 'package:thix_central/pages/events/models/event_models.dart';
import 'package:thix_central/pages/events/event_tickets_page.dart';
import 'package:thix_central/pages/events/events_home_page.dart';
import 'package:thix_central/pages/health/health_home_page.dart';
import 'package:thix_central/pages/jobs/jobs_home_page.dart';
import 'package:thix_central/pages/learning/learning_home_page.dart';
import 'package:thix_central/pages/social/social_home_page.dart';
import 'package:thix_central/pages/system/init_error_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(path: AppRoutes.initError, name: 'init_error', pageBuilder: (context, state) => const NoTransitionPage(child: InitErrorPage())),
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => const NoTransitionPage(child: ThixSplashPage()),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) {
          final next = state.uri.queryParameters['next'];
          return NoTransitionPage(child: ThixLoginPage(afterLoginRoute: next));
        },
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        pageBuilder: (context, state) => const NoTransitionPage(child: ThixSignUpPage()),
      ),
      GoRoute(
        path: AppRoutes.otpVerify,
        name: 'otp_verify',
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'];
          final pending = state.extra is Map<String, dynamic> ? state.extra as Map<String, dynamic> : null;
          return MaterialPage(child: ThixOtpVerifyPage(email: email, pendingProfile: pending));
        },
      ),
      GoRoute(
        path: AppRoutes.thixIdCard,
        name: 'thix_id_card',
        pageBuilder: (context, state) => const MaterialPage(child: ThixIdentityCardPage()),
      ),
      GoRoute(
        path: AppRoutes.events,
        name: 'events',
        pageBuilder: (context, state) => const MaterialPage(child: EventsHomePage()),
        routes: [
          GoRoute(path: 'tickets', name: 'events_tickets', pageBuilder: (context, state) => const MaterialPage(child: EventTicketsPage())),
          GoRoute(
            path: ':eventId',
            name: 'event_detail',
            pageBuilder: (context, state) {
              final eventId = state.pathParameters['eventId']!;
              final extra = state.extra is ThixEvent ? state.extra as ThixEvent : null;
              return MaterialPage(child: EventDetailPage(eventId: eventId, initialEvent: extra));
            },
          ),
        ],
      ),
      GoRoute(path: AppRoutes.reservation, name: 'reservation', pageBuilder: (context, state) => const MaterialPage(child: ReservationHomePage())),
      GoRoute(path: AppRoutes.health, name: 'health', pageBuilder: (context, state) => const MaterialPage(child: HealthHomePage())),
      GoRoute(path: AppRoutes.learning, name: 'learning', pageBuilder: (context, state) => const MaterialPage(child: LearningHomePage())),
      GoRoute(path: AppRoutes.social, name: 'social', pageBuilder: (context, state) => const MaterialPage(child: SocialHomePage())),
      GoRoute(path: AppRoutes.jobs, name: 'jobs', pageBuilder: (context, state) => const MaterialPage(child: JobsHomePage())),
      GoRoute(path: AppRoutes.news, name: 'news', pageBuilder: (context, state) => const MaterialPage(child: NewsHomePage())),
      GoRoute(
        path: AppRoutes.market,
        name: 'market',
        pageBuilder: (context, state) => const MaterialPage(child: MarketHomePage()),
        routes: [
          GoRoute(path: 'cart', name: 'market_cart', pageBuilder: (context, state) => const MaterialPage(child: MarketCartPage())),
          GoRoute(path: 'orders', name: 'market_orders', pageBuilder: (context, state) => const MaterialPage(child: MarketOrdersPage())),
          GoRoute(path: 'sell', name: 'market_sell', pageBuilder: (context, state) => const MaterialPage(child: MarketSellPage())),
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
  static const String splash = '/splash';
  static const String initError = '/init-error';
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String otpVerify = '/auth/verify';
  static const String thixIdCard = '/thix-id/card';
  static const String events = '/events';
  static const String eventsTickets = '/events/tickets';

  static String eventDetails(String id) => '/events/$id';
  static const String reservation = '/reservation';
  static const String health = '/health';
  static const String learning = '/learning';
  static const String social = '/social';
  static const String jobs = '/jobs';
  static const String news = '/news';
}
