import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_ecom/data/local/CachingProductRepository.dart';
import 'package:mini_ecom/data/models/product_model.dart'; // Import ProductModel for stubbing
import 'package:mini_ecom/data/remote/api_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart'; // <<--- ADD MOCKTAIL IMPORT

import 'package:mini_ecom/main.dart';

// --- MOCKS ---
// Simple mock for ApiHelper for this basic test
class MockApiHelper extends Mock implements ApiHelper {} // Use Mocktail for proper mocking

// Mock for CachingProductRepository
class MockCachingProductRepository extends Mock implements CachingProductRepository {}
// --- END MOCKS ---


void main() {
  late MockApiHelper mockApiHelper;late SharedPreferences sharedPreferences;
  late MockCachingProductRepository mockCachingProductRepository; // <<--- DECLARE THE MOCK

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async { // Make setUp async if using await inside
    mockApiHelper = MockApiHelper();
    sharedPreferences = await SharedPreferences.getInstance(); // Get the instance for tests
    mockCachingProductRepository = MockCachingProductRepository(); // <<--- INITIALIZE THE MOCK

    // It's good practice to provide default stubs for methods that might be called
    // by ProductBloc during initialization, even for a smoke test, to avoid null errors.
    when(() => mockCachingProductRepository.getProducts(
        limit: any(named: 'limit'),
        forceRefresh: any(named: 'forceRefresh')));// Default to empty list of products

    // If ProductBloc calls other methods on CachingProductRepository on init, stub them too.
    // For example, if you had category caching in CachingProductRepository:
    // when(() => mockCachingProductRepository.getCategories(forceRefresh: any(named: 'forceRefresh')))
    //     .thenAnswer((_) async => <CategoryModel>[]);
  });

  testWidgets('App smoke test - initial screen (likely SplashScreen or LoginScreen)', (WidgetTester tester) async {
    // 1. SharedPreferences is handled by setUpAll and getInstance in setUp.
    //    If you need specific initial values for *this test*:
    await sharedPreferences.setBool('isLoggedIn', false); // Example: Ensure logged out for LoginScreen

    // 2. ApiHelper mock is created in setUp.
    //    Stub methods on mockApiHelper if AuthBloc or other initial blocs call it.
    //    For a simple navigation to LoginScreen, often AuthBloc's CheckInitialAuthStatus
    //    is what matters, driven by SharedPreferences.

    // 3. SharedPreferences instance obtained in setUp.

    // Build our app and trigger a frame, providing the required parameters.
    await tester.pumpWidget(MyApp(
      apiHelper: mockApiHelper,
      sharedPreferences: sharedPreferences,
      cachingProductRepository: mockCachingProductRepository, // <<--- USE THE MOCK INSTANCE
    ));

    // After pumpWidget, the app initializes. SplashScreen will likely run.
    // Depending on SharedPreferences initial state (isLoggedIn = false),
    // it should navigate to LoginScreen.
    await tester.pumpAndSettle(); // Allow time for animations and async operations

    // Verify navigation to LoginScreen
    expect(find.text('Login'), findsOneWidget);
    // For more robustness, find by Key or Type if "Login" text is too generic
    // expect(find.byType(LoginScreen), findsOneWidget); // Assuming LoginScreen is a widget
  });
}

