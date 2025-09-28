import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_ecom/ui/splashscreen.dart';
import 'package:mini_ecom/ui/theme_provider/themeProvider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // <<--- IMPORT CONNECTIVITY

import 'bloc/auth%20bloc/auth_bloc.dart';
import 'bloc/cart_bloc/cart_bloc.dart';
import 'bloc/product_bloc/product_bloc.dart';
 // <<--- IMPORT ProductEvent for FetchHomeData
import 'bloc/signup_bloc/signup_bloc.dart';
import 'bloc/wishlist_bloc/wishlist_bloc.dart';

import 'data/local/database.dart';
import 'data/remote/api_helper.dart';
 // <<--- IMPORT DatabaseHelper
// Import your Network (Dio-based) Product Repository
import 'data/remote/product_repo.dart' as NetworkProductRepo; // <<--- IMPORT NetworkProductRepository
// Import CachingProductRepository
import 'data/local/CachingProductRepository.dart'; // <<--- IMPORT CachingProductRepository (Ensure path is correct)


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Common Dependencies
  final ApiHelper apiHelper = ApiHelper();
  final SharedPreferences sharedPreferences =
  await SharedPreferences.getInstance();
  final DatabaseHelper databaseHelper = DatabaseHelper(); // <<--- INITIALIZE DatabaseHelper
  final Connectivity connectivity = Connectivity(); // <<--- INITIALIZE Connectivity

  // Network-only Product Repository (Dio-based)
  final NetworkProductRepo.ProductRepository networkProductRepository =
  NetworkProductRepo.ProductRepository(); // <<--- INITIALIZE NetworkProductRepository

  // Caching Product Repository
  final CachingProductRepository cachingProductRepository = CachingProductRepository(
    networkProductRepository: networkProductRepository,
    dbHelper: databaseHelper,
    connectivity: connectivity,
  ); // <<--- INITIALIZE CachingProductRepository

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(
        apiHelper: apiHelper,
        sharedPreferences: sharedPreferences,
        // Pass CachingProductRepository to MyApp if other widgets/routes need it directly,
        // or just ensure it's provided to ProductBloc below.
        // For BLoC provision, we don't strictly need to pass it to MyApp constructor,
        // but it's good practice if it might be used elsewhere or for clarity.
        cachingProductRepository: cachingProductRepository,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final ApiHelper apiHelper;
  final SharedPreferences sharedPreferences;
  final CachingProductRepository cachingProductRepository; // <<--- ACCEPT CachingProductRepository

  const MyApp({
    super.key,
    required this.apiHelper,
    required this.sharedPreferences,
    required this.cachingProductRepository, // <<--- RECEIVE CachingProductRepository
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>(
              create: (context) => AuthBloc(
                apiHelper: apiHelper,
                sharedPreferences: sharedPreferences,
              )..add( CheckInitialAuthStatus()),
            ),
            BlocProvider<ProductBloc>(
              create: (context) => ProductBloc(
                apiHelper: apiHelper, // Still needed for categories as per ProductBloc's constructor
                cachingProductRepository: cachingProductRepository, // <<--- PROVIDE CachingProductRepository
              )..add(const FetchHomeData(forceRefresh: false)), // Dispatch initial event
            ),
            BlocProvider<SignUpBloc>(
              create: (context) => SignUpBloc(
                apiHelper: apiHelper,
              ),
            ),
            BlocProvider<CartBloc>(
              create: (context) =>
              CartBloc(sharedPreferences: sharedPreferences)..add(LoadCart()),
            ),
            BlocProvider<WishlistBloc>(
              create: (context) =>
              WishlistBloc(sharedPreferences: sharedPreferences)
                ..add(LoadWishlist()),
            ),
          ],
          child: MaterialApp(
            title: 'Mini ECom App',
            themeMode: themeProvider.themeMode,
            theme: ThemeData( // Your light theme definition
              brightness: Brightness.light,
              primarySwatch: Colors.deepPurple,
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.grey[100],
              appBarTheme: const AppBarTheme(
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
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              ),
              bottomNavigationBarTheme: BottomNavigationBarThemeData(
                backgroundColor: Colors.white,
                selectedItemColor: Colors.deepPurple,
                unselectedItemColor: Colors.grey[600],
                elevation: 8.0,
              ),
              colorScheme: ColorScheme.fromSwatch(
                primarySwatch: Colors.deepPurple,
                brightness: Brightness.light,
              ).copyWith(
                secondary: Colors.amber,
                surfaceVariant: Colors.grey.shade200,
              ),
            ),
            darkTheme: ThemeData( // Your dark theme definition
              brightness: Brightness.dark,
              primarySwatch: Colors.deepPurple,
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.grey[900],
              appBarTheme: AppBarTheme(
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
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
              ),
              cardTheme: CardThemeData(
                elevation: 3,
                color: Colors.grey[850],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              ),
              bottomNavigationBarTheme: BottomNavigationBarThemeData(
                backgroundColor: Colors.grey[850],
                selectedItemColor: Colors.deepPurple.shade200,
                unselectedItemColor: Colors.grey[500],
                elevation: 8.0,
              ),
              colorScheme: ColorScheme.fromSwatch(
                primarySwatch: Colors.deepPurple,
                brightness: Brightness.dark,
              ).copyWith(
                secondary: Colors.amberAccent,
                surface: Colors.grey[850],
                onSurface: Colors.white,
                surfaceVariant: Colors.grey[700],
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

