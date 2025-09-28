import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Ensure these paths are correct for your project structure
import '../../data/models/category%20model.dart'; // Corrected import name
import '../../data/models/product_model.dart';
import '../../data/remote/api_helper.dart';
import '../../data/remote/app_exceptions.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ApiHelper _apiHelper;

  ProductBloc({required ApiHelper apiHelper})
      : _apiHelper = apiHelper,
        super(ProductInitial()) {
    on<FetchHomeData>(_onFetchHomeData);
    on<FetchProductsByCategory>(_onFetchProductsByCategory); // <--- REGISTER HANDLER
    // TODO: Add handlers for SearchProducts
  }

  Future<void> _onFetchHomeData(
      FetchHomeData event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      // Fetch categories
      final dynamic categoriesApiResponse =
      await _apiHelper.getApi("products/categories");

      if (categoriesApiResponse is! List) {
        throw Exception(
            "Categories API did not return a list. Response: $categoriesApiResponse");
      }
      final List<CategoryModel> categories = (categoriesApiResponse)
          .map((categoryJson) {
        if (categoryJson is Map<String, dynamic>) {
          final String? categoryName = categoryJson['name'] as String?;
          // The dummyjson categories endpoint also returns 'slug' and 'url'
          // We are primarily using 'name' for display and 'slug' (or transformed name) for API calls.
          // For simplicity, CategoryModel currently only has 'name'.
          // If you add 'slug' to CategoryModel, parse it here:
          // final String? categorySlug = categoryJson['slug'] as String?;
          if (categoryName == null) {
            print(
                "ProductBloc Warning: Category object missing 'name' field: $categoryJson");
            return null;
          }
          return CategoryModel(name: categoryName); // Potentially also pass slug
        } else {
          print(
              "ProductBloc Warning: Unexpected item type in categories list: $categoryJson");
          return null;
        }
      })
          .whereType<CategoryModel>()
          .toList();

      // Fetch featured products
      final dynamic productsApiResponse =
      await _apiHelper.getApi("products", queryParams: {"limit": "10"});

      if (productsApiResponse is! Map<String, dynamic> ||
          productsApiResponse['products'] is! List) {
        throw Exception(
            "Products API response is not in the expected format. Response: $productsApiResponse");
      }
      final List<ProductModel> featuredProducts =
      (productsApiResponse['products'] as List).map((productJson) {
        if (productJson is Map<String, dynamic>) {
          return ProductModel.fromJson(productJson);
        } else {
          print(
              "ProductBloc Warning: Unexpected item type in products list: $productJson");
          return null;
        }
      }).whereType<ProductModel>().toList();

      print("ProductBloc: Categories fetched: ${categories.length}");
      print("ProductBloc: Featured products fetched: ${featuredProducts.length}");

      emit(ProductHomeDataLoaded(
          categories: categories, featuredProducts: featuredProducts));
    } on AppException catch (e) {
      print("ProductBloc Error (AppException - HomeData): ${e.toString()} URL: ${e.url}");
      emit(ProductError(message: e.message!)); // Use e.message directly
    } catch (e, stackTrace) {
      print("ProductBloc Error (Unknown - HomeData): ${e.toString()}");
      print("ProductBloc StackTrace (HomeData): $stackTrace");
      emit(ProductError(
          message:
          "An unexpected error occurred while fetching home data: ${e.toString()}"));
    }
  }

  // --- NEW METHOD TO FETCH PRODUCTS BY CATEGORY ---
  Future<void> _onFetchProductsByCategory(
      FetchProductsByCategory event, Emitter<ProductState> emit) async {
    // It's good practice to ensure the previous state is not an error state
    // or to emit a specific loading state that ProductsByCategoryScreen can uniquely identify.
    // For now, using ProductLoading.
    emit(ProductLoading());
    try {
      // The dummyjson API for categories uses the actual category name (slug) in the path.
      // e.g., "smartphones", "laptops", "home-decoration"
      // The event.categorySlug should ideally be this API-friendly name.
      // If your CategoryModel.name is "Home Decoration", you need to transform it.
      // final String apiCategoryName = event.categorySlug.toLowerCase().replaceAll(' ', '-');
      // Assuming event.categorySlug is already in the correct format (like 'smartphones')
      final String apiCategoryName = event.categorySlug;


      print("ProductBloc: Fetching products for category API name: $apiCategoryName");

      final dynamic responseData =
      await _apiHelper.getApi("products/category/$apiCategoryName");

      if (responseData != null && responseData['products'] is List) {
        final List<ProductModel> products = (responseData['products'] as List)
            .map((productJson) {
          if (productJson is Map<String, dynamic>) {
            return ProductModel.fromJson(productJson);
          }
          print("ProductBloc Warning: Unexpected item type in category products list: $productJson");
          return null;
        })
            .whereType<ProductModel>() // Filter out nulls
            .toList();

        print("ProductBloc: Products fetched for ${event.categorySlug}: ${products.length}");
        emit(ProductsByCategoryLoaded(
            products: products, categoryName: event.categorySlug // Pass original slug/name for UI
        ));
      } else {
        print(
            "ProductBloc: Unexpected response structure for category products '$apiCategoryName': $responseData");
        emit(ProductError(
            message:
            "Could not load products for ${event.categorySlug}. Invalid response."));
      }
    } on AppException catch (e) {
      print(
          "ProductBloc Error (AppException - Category Products): ${e.toString()} URL: ${e.url}");
      emit(ProductError(message: "Failed to load products: ${e.message}"));
    } catch (e, stackTrace) {
      print(
          "ProductBloc Error (Unknown - Category Products): ${e.toString()}");
      print("ProductBloc StackTrace (Category Products): $stackTrace");
      emit(ProductError(
          message:
          "An error occurred fetching products for ${event.categorySlug}: ${e.toString()}"));
    }
  }
}
