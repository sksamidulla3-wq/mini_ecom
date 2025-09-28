import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_ecom/ui/splashscreen.dart';
import 'package:mini_ecom/ui/theme_provider/themeProvider.dart';
import 'package:provider/provider.dart'; // <-- IMPORT PROVIDER
import 'package:shared_preferences/shared_preferences.dart';

import 'bloc/auth%20bloc/auth_bloc.dart';
import 'bloc/cart_bloc/cart_bloc.dart';
import 'bloc/product_bloc/product_bloc.dart';
import 'bloc/signup_bloc/signup_bloc.dart';
import 'bloc/wishlist_bloc/wishlist_bloc.dart';
import 'data/remote/api_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final ApiHelper apiHelper = ApiHelper();
  final SharedPreferences sharedPreferences =
  await SharedPreferences.getInstance();

  runApp(
    // Wrap with ChangeNotifierProvider for ThemeProvider
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(apiHelper: apiHelper, sharedPreferences: sharedPreferences),
    ),
  );
}

class MyApp extends StatelessWidget {
  final ApiHelper apiHelper;
  final SharedPreferences sharedPreferences;

  const MyApp({
    super.key,
    required this.apiHelper,
    required this.sharedPreferences,
  });

  @override
  Widget build(BuildContext context) {
    // Access ThemeProvider to set the themeMode for MaterialApp
    // Using Consumer here ensures MaterialApp rebuilds when themeMode changes.
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MultiBlocProvider( // Your existing MultiBlocProvider
          providers: [
            BlocProvider<AuthBloc>(
              create: (context) => AuthBloc(
                apiHelper: apiHelper,
                sharedPreferences: sharedPreferences,
              )..add(CheckInitialAuthStatus()), // Add your initial event if any
            ),
            BlocProvider<ProductBloc>(
              create: (context) =>
              ProductBloc(apiHelper: apiHelper)..add(FetchHomeData()),
            ),
            BlocProvider<SignUpBloc>(
              create: (context) => SignUpBloc(
                apiHelper: apiHelper,
              ),
            ),
            BlocProvider<CartBloc>(
              create: (context) =>
              CartBloc(sharedPreferences: sharedPreferences)
                ..add(LoadCart()),
            ),
            BlocProvider<WishlistBloc>(
              create: (context) =>
              WishlistBloc(sharedPreferences: sharedPreferences)
                ..add(LoadWishlist()),
            ),
          ],
          child: MaterialApp(
            title: 'Mini ECom App',
            themeMode: themeProvider.themeMode, // <-- USE THEME MODE FROM PROVIDER
            theme: ThemeData( // Your light theme definition
              brightness: Brightness.light,
              primarySwatch: Colors.deepPurple,
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.grey[100], // Example light background
              appBarTheme: AppBarTheme( // Consistent AppBar style for light theme
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                elevation: 1,
              ),
              inputDecorationTheme: const InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                  borderSide: BorderSide(color: Colors.deepPurple, width: 2.0),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
              ),
              cardTheme: CardThemeData( // Example light card theme
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              ),
              bottomNavigationBarTheme: BottomNavigationBarThemeData( // Example light bottom nav
                backgroundColor: Colors.white,
                selectedItemColor: Colors.deepPurple,
                unselectedItemColor: Colors.grey[600],
                elevation: 8.0,
              ),
              colorScheme: ColorScheme.fromSwatch(
                primarySwatch: Colors.deepPurple,
                brightness: Brightness.light,
              ).copyWith(
                secondary: Colors.amber, // Define a secondary color
                surfaceVariant: Colors.grey.shade200, // For things like disabled text field fill
              ),
            ),
            darkTheme: ThemeData( // Your dark theme definition
              brightness: Brightness.dark,
              primarySwatch: Colors.deepPurple, // You might want a different primary for dark
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.grey[900], // Example dark background
              appBarTheme: AppBarTheme( // Consistent AppBar style for dark theme
                backgroundColor: Colors.grey[850],
                foregroundColor: Colors.white,
                elevation: 1,
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(12.0)),
                  borderSide: BorderSide(color: Colors.deepPurple.shade300, width: 2.0),
                ),
                filled: true,
                fillColor: Colors.grey[800],
                hintStyle: TextStyle(color: Colors.grey[400]),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple.shade300,
                  foregroundColor: Colors.black, // Text on dark button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
              ),
              cardTheme: CardThemeData( // Example dark card theme
                elevation: 3,
                color: Colors.grey[850],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              ),
              bottomNavigationBarTheme: BottomNavigationBarThemeData( // Example dark bottom nav
                backgroundColor: Colors.grey[850],
                selectedItemColor: Colors.deepPurple.shade200,
                unselectedItemColor: Colors.grey[500],
                elevation: 8.0,
              ),
              colorScheme: ColorScheme.fromSwatch(
                primarySwatch: Colors.deepPurple, // Or Colors.purple, etc.
                brightness: Brightness.dark,
              ).copyWith(
                secondary: Colors.amberAccent, // Define a secondary color for dark
                surface: Colors.grey[850], // Base surface color
                onSurface: Colors.white, // Text/icons on surface
                surfaceVariant: Colors.grey[700], // For things like text field fill
              ),
            ),
            home: const SplashScreen(),
            debugShowCheckedModeBanner: false,
          ),
        );
      },
    );
  }
}

