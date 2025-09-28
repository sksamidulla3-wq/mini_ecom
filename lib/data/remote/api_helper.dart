import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'app_exceptions.dart'; // Ensure this file exists and is correct

class ApiHelper {
  final String _productBaseUrl = "https://dummyjson.com";

  Future<dynamic> getApi(String endpoint, {Map<String, String>? queryParams}) async {
    dynamic responseJson;
    // Construct the full URI using the base URL, endpoint, and any query parameters
    // Ensure endpoint doesn't start with / if _productBaseUrl doesn't end with one
    final String path = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    final Uri uri = Uri.parse("$_productBaseUrl/$path").replace(queryParameters: queryParams);

    print("ApiHelper (GET): Request URL: $uri");

    try {
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      ).timeout(const Duration(seconds: 20));

      responseJson = _processResponse(response);
    } on SocketException {
      print("ApiHelper Error (GET): No Internet connection (SocketException)");
      throw FetchDataException('No Internet connection. Please check your network.');
    } on TimeoutException {
      print("ApiHelper Error (GET): API not responding in time (TimeoutException)");
      throw ApiNotRespondingException('The server took too long to respond.');
    } catch (e) {
      print("ApiHelper Error (Unknown during GET): ${e.toString()}");
      throw Exception('An unexpected error occurred during GET request: ${e.toString()}');
    }
    return responseJson;
  }

  // --- MODIFIED: POST API METHOD ---
  Future<dynamic> postApi(
      String pathOrUrl, // Renamed to clarify its dual nature
      Map<String, dynamic> body, {
        Map<String, String>? customHeaders,
        bool isFullUrl = false, // Default to false, meaning pathOrUrl is an endpoint
      }) async {
    dynamic responseJson;
    Uri uri;

    if (isFullUrl) {
      uri = Uri.parse(pathOrUrl);
    } else {
      // Construct the full URI using the base URL and the endpoint
      // Ensure endpoint doesn't start with / if _productBaseUrl doesn't end with one
      final String path = pathOrUrl.startsWith('/') ? pathOrUrl.substring(1) : pathOrUrl;
      uri = Uri.parse("$_productBaseUrl/$path");
    }

    try {
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        ...?customHeaders,
      };

      print("ApiHelper (POST): Request URL: $uri"); // Now printing the constructed Uri
      print("ApiHelper (POST): Request Body: ${jsonEncode(body)}");
      print("ApiHelper (POST): Request Headers: $headers");

      final response = await http.post(
        uri, // Use the constructed Uri
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      responseJson = _processResponse(response);
    } on SocketException {
      print("ApiHelper Error (POST): No Internet connection (SocketException)");
      throw FetchDataException('No Internet connection. Please check your network and try again.');
    } on TimeoutException {
      print("ApiHelper Error (POST): API not responding in time (TimeoutException)");
      throw ApiNotRespondingException('The server took too long to respond. Please try again later.');
    } catch (e) {
      print("ApiHelper Error (Unknown during POST): ${e.toString()}");
      // Consider rethrowing a more specific custom exception if possible
      throw Exception('An unexpected error occurred during the API request: ${e.toString()}');
    }
    return responseJson;
  }

  dynamic _processResponse(http.Response response) {
    print("ApiHelper: Response Status Code: ${response.statusCode}");
    if (response.body.isNotEmpty) {
      if (response.body.length < 500) {
        print("ApiHelper: Response Body: ${response.body}");
      } else {
        print("ApiHelper: Response Body (truncated, >500 chars): ${response.body.substring(0, 500)}...");
      }
    } else {
      print("ApiHelper: Response Body: Is Empty");
    }


    switch (response.statusCode) {
      case 200:
      case 201:
        try {
          var responseJson = jsonDecode(response.body);
          return responseJson;
        } catch (e) {
          // If body is not valid JSON but status is 200/201, this is an issue.
          // Or sometimes APIs return non-JSON success responses (e.g., plain text or empty)
          print("ApiHelper Warning: Could not decode JSON for success response. Body: ${response.body}");
          // Depending on API contract, you might return raw body or throw error.
          // For now, let's assume JSON is expected for 200/201.
          throw FetchDataException(
              'Invalid JSON format in success response from server. Status: ${response.statusCode}',
              response.request?.url.toString());
        }
      case 400:
        var errorJson = jsonDecode(response.body);
        throw BadRequestException(
            errorJson['message'] ?? response.body, response.request?.url.toString());
      case 401:
      case 403:
        var errorJson = jsonDecode(response.body);
        throw UnauthorisedException(
            errorJson['message'] ?? response.body, response.request?.url.toString());
      case 404:
        throw FetchDataException(
            'Resource not found (404). URL: ${response.request?.url.toString()}',
            response.request?.url.toString());
      case 500:
      default:
        throw FetchDataException(
            'Error from server (Code: ${response.statusCode}). Response: ${response.body}',
            response.request?.url.toString());
    }
  }
}
