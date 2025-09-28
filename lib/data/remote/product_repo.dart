// lib/data/remote/product_repo.dart (Your Dio-based repository)
import 'package:dio/dio.dart';

class ProductRepository {
  final Dio dio = Dio(BaseOptions(baseUrl: "https://dummyjson.com/"));

  // Modified to accept an optional category parameter
  Future<List<dynamic>> fetchProducts({String? category, int? limit}) async {
    String path = "products";
    Map<String, dynamic> queryParams = {};

    if (category != null && category.isNotEmpty) {
      path = "products/category/$category";
    }

    if (limit != null) {
      queryParams['limit'] = limit;
    }

    final response = await dio.get(path, queryParameters: queryParams.isNotEmpty ? queryParams : null);

    if (response.statusCode == 200 && response.data != null && response.data['products'] is List) {
      return response.data["products"];
    } else {
      print("Failed to load products. Path: $path, Status: ${response.statusCode}, Data: ${response.data}");
      throw Exception("Failed to load products");
    }
  }

  Future<Map<String, dynamic>> fetchProductDetail(int id) async {
    final response = await dio.get("products/$id");
    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception("Failed to load product detail");
    }
  }

// If you decide to add a specific method for categories (optional but clean)
// Future<List<dynamic>> fetchRawCategories() async {
//   final response = await dio.get("products/categories");
//   if (response.statusCode == 200 && response.data is List) {
//     return response.data;
//   } else {
//     throw Exception("Failed to load categories");
//   }
// }
}
