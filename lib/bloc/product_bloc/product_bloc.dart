import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Ensure these paths are correct for your project structure
import '../../data/local/CachingProductRepository.dart'; // Corrected import based on your file
import '../../data/models/category%20model.dart';
import '../../data/models/product_model.dart';
import '../../data/remote/api_helper.dart'; // Keep for categories
import '../../data/remote/app_exceptions.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ApiHelper _apiHelper; // Keep for fetching categories
  final CachingProductRepository _cachingProductRepository;

  ProductBloc({
    required ApiHelper apiHelper,
    required CachingProductRepository cachingProductRepository,
  })  : _apiHelper = apiHelper,
        _cachingProductRepository = cachingProductRepository,
        super(ProductInitial()) {
    on<FetchHomeData>(_onFetchHomeData);
    on<FetchProductsByCategory>(_onFetchProductsByCategory);
  }

  Future<void> _onFetchHomeData(
      FetchHomeData event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      // Fetch categories - Stays the same, uses _apiHelper
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
          if (categoryName == null) {
            print("ProductBloc Warning: Category object missing 'name' field: $categoryJson");
            return null;
          }
          return CategoryModel(name: categoryName);
        } else {
          print("ProductBloc Warning: Unexpected item type in categories list: $categoryJson");
          return null;
        }
      }).whereType<CategoryModel>().toList();

      // Fetch featured products - NOW USES _cachingProductRepository and passes limit
      final List<ProductModel> featuredProducts =
      await _cachingProductRepository.getProducts(
        forceRefresh: event.forceRefresh ?? false,
        limit: 10, // <<--- EXPLICITLY PASSING THE LIMIT
      );
      // Now, CachingProductRepository.getProducts (and its underlying _fetchAndCacheProductsFromApi)
      // should ideally use this limit when fetching from the network to avoid over-fetching.
      // If the cache already has more than 10 items, the repository might return
      // the cached items and the limit could be applied there or here.
      // For consistency, if limit is passed, the repo should aim to return at most that many.

      print("ProductBloc: Categories fetched: ${categories.length}");
      print("ProductBloc: Featured products fetched: ${featuredProducts.length}"); // Should be <= 10 if repo respects limit

      emit(ProductHomeDataLoaded(
        categories: categories,
        featuredProducts: featuredProducts, // No longer need .take(10) if repo handles limit
      ));

    } on AppException catch (e) {
      print("ProductBloc Error (AppException - HomeData): ${e.toString()} URL: ${e.url}");
      emit(ProductError(message: e.message!));
    } catch (e, stackTrace) {
      print("ProductBloc Error (Unknown - HomeData): ${e.toString()}");
      print("ProductBloc StackTrace (HomeData): $stackTrace");
      emit(ProductError(
          message:
          "An unexpected error occurred while fetching home data: ${e.toString()}"));
    }
  }

  Future<void> _onFetchProductsByCategory(
      FetchProductsByCategory event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      final String apiCategoryName = event.categorySlug;
      print("ProductBloc: Fetching products for category API name: $apiCategoryName");

      final List<ProductModel> products =
      await _cachingProductRepository.getProductsByCategory(
        categorySlug: apiCategoryName,
        forceRefresh: event.forceRefresh ?? false,
      );

      print("ProductBloc: Products fetched for ${event.categorySlug}: ${products.length}");
      emit(ProductsByCategoryLoaded(
          products: products, categoryName: event.categorySlug));
    } on AppException catch (e) {
      print("ProductBloc Error (AppException - Category Products): ${e.toString()} URL: ${e.url}");
      emit(ProductError(message: e.message!));
    } catch (e, stackTrace) {
      print("ProductBloc Error (Unknown - Category Products): ${e.toString()}");
      print("ProductBloc StackTrace (Category Products): $stackTrace");
      emit(ProductError(
          message:
          "An error occurred fetching products for ${event.categorySlug}: ${e.toString()}"));
    }
  }
}
