import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';// No need to import SharedPreferences here if AuthBloc handles it
// import 'package:shared_preferences/shared_preferences.dart';

import '../../bloc/auth bloc/auth_bloc.dart';
// No need for UserModel here if AuthBloc handles it for AuthSuccess state
// import '../../data/models/user_model.dart';
import 'homescreen.dart';
import 'onboarding/login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SplashScreenState();
  }
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimationLogo;
  late Animation<Offset> _slideAnimationTitle;

  final Duration _splashVisualDuration = const Duration(seconds: 3);
  bool _isSplashVisualsComplete = false; // Flag to track visual completion

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimationLogo = Tween<Offset>(
      begin: const Offset(0, 0.5), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.elasticOut));
    _slideAnimationTitle = Tween<Offset>(
      begin: const Offset(0, 0.8), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Interval(0.3, 1.0, curve: Curves.elasticOut)));

    _startSplashVisuals();
  }

  Future<void> _startSplashVisuals() async {
    _animationController.forward();
    await Future.delayed(_splashVisualDuration);
    if (mounted) {
      setState(() {
        _isSplashVisualsComplete = true;
      });
      _triggerNavigationIfReady();
    }
  }

  void _triggerNavigationIfReady() {
    if (_isSplashVisualsComplete && mounted) {
      final currentAuthState = context.read<AuthBloc>().state;
      if (currentAuthState is AuthSuccess) {
        print("SplashScreen (_triggerNavigationIfReady): AuthSuccess, navigating to HomeScreen.");
        _navigateTo(const HomeScreen());
        // ----------- CORRECTION HERE -----------
      } else if (currentAuthState is AuthInitial && currentAuthState.isLoggedOut) {
        // ----------- END CORRECTION -----------
        print("SplashScreen (_triggerNavigationIfReady): AuthInitial (LoggedOut), navigating to LoginScreen.");
        _navigateTo(const LoginScreen());
      } else if (currentAuthState is AuthFailure) {
        print("SplashScreen (_triggerNavigationIfReady): AuthFailure, navigating to LoginScreen.");
        _navigateTo(const LoginScreen());
      }
    }
  }

  void _navigateTo(Widget screen) {
    if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (_isSplashVisualsComplete) {
          if (state is AuthSuccess) {
            print("SplashScreen (BlocListener): AuthSuccess, navigating to HomeScreen.");
            _navigateTo(const HomeScreen());
            // ----------- CORRECTION HERE -----------
          } else if (state is AuthInitial && state.isLoggedOut) {
            // ----------- END CORRECTION -----------
            print("SplashScreen (BlocListener): AuthInitial (LoggedOut), navigating to LoginScreen.");
            _navigateTo(const LoginScreen());
          } else if (state is AuthFailure) {
            print("SplashScreen (BlocListener): AuthFailure, navigating to LoginScreen.");
            _navigateTo(const LoginScreen());
          }
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimationLogo,
                  child: Icon(
                    Icons.shopping_cart_checkout_rounded,
                    size: 120.0,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimationTitle,
                  child: Text(
                    "Mini ECom",
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48.0),
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  width: 180,
                  child: LinearProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                    backgroundColor: colorScheme.primary.withOpacity(0.2),
                    minHeight: 5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

