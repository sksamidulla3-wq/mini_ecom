import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final Dio dio = Dio(BaseOptions(baseUrl: "https://dummyjson.com/"));

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await dio.post(
      "auth/login",
      data: {
        "username": username,
        "password": password,
      },
      options: Options(headers: {"Content-Type": "application/json"}),
    );

    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("accessToken", response.data["accessToken"]);
      return response.data;
    } else {
      throw Exception("Login failed");
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("accessToken");
  }
}
