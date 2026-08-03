import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndNavigate();
    });
  }

  void _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted || _hasNavigated) return;

    final state = ref.read(authNotifierProvider);
    if (state is! AuthInitial && state is! AuthLoading) {
      _navigateBasedOnAuth(state);
    }
  }

  void _navigateBasedOnAuth(AuthState authState) {
    if (!mounted || _hasNavigated) return;

    if (authState is AuthAuthenticated) {
      _hasNavigated = true;
      if (authState.user['hasProfile'] == false) {
        context.go('/profile-setup');
      } else {
        context.go('/home');
      }
    } else if (authState is AuthPendingOTP) {
      _hasNavigated = true;
      context.go('/verify-otp', extra: authState.email);
    } else if (authState is AuthUnauthenticated || authState is AuthError) {
      _hasNavigated = true;
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to Auth State to redirect
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      _navigateBasedOnAuth(next);
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: Center(
          child: ScaleTransition(
            scale: _animation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 90,
                ),
                const SizedBox(height: 16),
                Text(
                  'tinder',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                      ),
                ),
                const SizedBox(height: 48),
                const CircularProgressIndicator(
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
