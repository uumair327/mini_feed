import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import '../pages/auth/login_page.dart';
import '../pages/feed/feed_page.dart';
import '../widgets/common/loading_indicators.dart';

/// App router that handles navigation based on authentication state
class AppRouter {
  static const String loginRoute = '/login';
  static const String feedRoute = '/feed';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case loginRoute:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
          settings: settings,
        );
      case feedRoute:
        return MaterialPageRoute(
          builder: (_) => const FeedPage(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const AuthWrapper(),
          settings: settings,
        );
    }
  }
}

/// Wrapper that determines which screen to show based on auth state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return const Scaffold(
            body: CenteredLoadingIndicator(
              message: 'Checking authentication...',
            ),
          );
        }
        
        if (state is AuthSuccess) {
          return const FeedPage();
        }
        
        return const LoginPage();
      },
    );
  }
}

/// Navigation helper methods
class AppNavigation {
  static void toLogin(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.loginRoute,
      (route) => false,
    );
  }

  static void toFeed(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.feedRoute,
      (route) => false,
    );
  }

  static void logout(BuildContext context) {
    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }
}