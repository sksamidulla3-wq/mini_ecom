import 'package:dio/dio.dart';

class ProductRepository {
  final Dio dio = Dio(BaseOptions(baseUrl: "https://dummyjson.com/"));

  Future<List<dynamic>> fetchProducts() async {
    final response = await dio.get("products");
    if (response.statusCode == 200) {
      return response.data["products"];
    } else {
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
}
