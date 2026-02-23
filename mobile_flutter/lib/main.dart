import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';

import 'auth/login_screen.dart';
import 'auth/registration_screen.dart';
import 'passenger/passenger_dashboard.dart';
import 'driver/driver_dashboard.dart';
import 'driver/driver_requests_screen.dart';
import 'driver/driver_earnings_screen.dart';
import 'driver/driver_profile_screen.dart';

import 'presentation/screens/driver_verification_screen.dart';
import 'presentation/screens/splash_screen.dart';
import 'admin/admin_dashboard.dart';
import 'presentation/screens/create_ride_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/wallet_screen.dart';
import 'presentation/screens/ride_search_results_screen.dart';
import 'presentation/screens/ride_booking_screen.dart';
import 'presentation/screens/ride_history_screen.dart';
import 'presentation/screens/safety_screen.dart';
import 'presentation/screens/active_ride_screen.dart';
import 'profile/settings_screen.dart';
import 'profile/edit_profile_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('settings');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: MyApp()));
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegistrationScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const PassengerDashboard(),
      ),
      GoRoute(
        path: '/driver_home',
        builder: (context, state) => const DriverDashboard(),
      ),
      GoRoute(
        path: '/driver_requests',
        builder: (context, state) => const DriverRequestsScreen(),
      ),
      GoRoute(
        path: '/driver_earnings',
        builder: (context, state) => const DriverEarningsScreen(),
      ),
      GoRoute(
        path: '/driver_profile',
        builder: (context, state) => const DriverProfileScreen(),
      ),
      GoRoute(
        path: '/driver_verification',
        builder: (context, state) => const DriverVerificationScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/create-ride',
        builder: (context, state) => const CreateRideScreen(),
      ),
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/ride-search',
        builder: (context, state) {
           final extra = state.extra as Map<String, dynamic>?;
           final pickup = extra?['pickup'];
           final drop = extra?['drop'];
           return RideSearchResultsScreen(pickup: pickup, drop: drop);
        },
      ),
      GoRoute(
        path: '/ride-booking',
        builder: (context, state) => const RideBookingScreen(),
      ),
      GoRoute(
        path: '/ride-history',
        builder: (context, state) => const RideHistoryScreen(),
      ),
      GoRoute(
        path: '/safety',
        builder: (context, state) => const SafetyScreen(),
      ),
      GoRoute(
        path: '/active-ride',
        builder: (context, state) {
           final bookingId = state.extra as String?;
           return ActiveRideScreen(bookingId: bookingId ?? '');
        },
      ),
    ],
    redirect: (context, state) async {
       final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final location = state.uri.toString();
      
      final isSplash = location == '/';
      final isAuthRoute = location == '/login' || location == '/register';

      if (isSplash) return null; // Let splash handle navigation

      if (!isLoggedIn && !isAuthRoute) return '/login';
      
      return null;
    },
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeControllerProvider);

    return MaterialApp.router(
      title: 'GoTogether',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
