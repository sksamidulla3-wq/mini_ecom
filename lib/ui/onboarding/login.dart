import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_ecom/ui/onboarding/signup.dart';
import '../../bloc/auth bloc/auth_bloc.dart';
import '../homescreen.dart';
 // To navigate after login

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  // Pre-fill for faster testing, remove 'text' for production
  final _usernameController = TextEditingController(text: "emilys");
  final _passwordController = TextEditingController(text: "emilyspass");
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _performLogin() {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus(); // Hide keyboard
      context.read<AuthBloc>().add(
        LoginRequested(
          username: _usernameController.text.trim(),
          password: _passwordController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // Removed AppBar for a cleaner, more modern full-screen login feel
      // appBar: AppBar(title: const Text("Login - Mini ECom")),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Login Failed: ${state.errorMessage}"),
                backgroundColor: colorScheme.error,
                behavior: SnackBarBehavior.floating, // More modern
              ),
            );
          } else if (state is AuthSuccess) {
            // No need for SnackBar here if navigating immediately
            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(
            //     content: Text("Login Successful! Welcome, ${state.user.firstName}!"),
            //     backgroundColor: Colors.green,
            //     behavior: SnackBarBehavior.floating,
            //   ),
            // );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        },
        child: SafeArea( // Ensures content is not obscured by system UI
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch, // Makes button full width
                  children: <Widget>[
                    // App Logo (Optional, but adds to UI)
                    Icon(
                      Icons.shopping_cart_checkout_rounded,
                      size: 80,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Welcome Back!",
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Login to continue your shopping journey.",
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Username Field
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: "Username",
                        prefixIcon: const Icon(Icons.person_outline),
                        // Using theme's input decoration
                        // border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        // filled: true,
                        // fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your username';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 20),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                        // border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        // filled: true,
                        // fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _performLogin(), // Login on done
                    ),
                    const SizedBox(height: 12),

                    // Forgot Password (Optional)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Forgot Password clicked (not implemented)')),
                          );
                        },
                        child: Text(
                          'Forgot Password?',
                          style: textTheme.bodySmall?.copyWith(color: colorScheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login Button
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        if (state is AuthLoading && !state.isRestoringSession) { // Check it's not session restore loading
                          return const Center(child: CircularProgressIndicator());
                        }
                        return ElevatedButton(
                          onPressed: _performLogin,
                          // Style is now primarily from ElevatedButtonTheme in main.dart
                          // style: ElevatedButton.styleFrom(
                          //   padding: const EdgeInsets.symmetric(vertical: 16),
                          //   textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          // ),
                          child: const Text("Login"),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Sign Up Navigation
                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'Sign Up',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                                decoration: TextDecoration.underline,
                                decorationColor: colorScheme.primary,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  // Navigate to SignUpScreen
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20), // Bottom padding
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
