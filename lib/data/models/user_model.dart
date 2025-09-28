import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String gender;
  final String image;
  final String token; // This will store the access token

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.image,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // According to your log, the map has 'accessToken' and also all other user fields.
    // The standard dummyjson login response has 'token' for the access token.
    // Let's prioritize 'token' if it exists, otherwise use 'accessToken' based on your log.
    String? foundToken = json['token'] as String?; // Try standard 'token' first
    foundToken ??= json['accessToken'] as String?;

    if (foundToken == null) {
      // If neither 'token' nor 'accessToken' is found, this is an issue.
      throw Exception("Access token not found in JSON response under 'token' or 'accessToken' key.");
    }

    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,lastName: json['lastName'] as String,
      gender: json['gender'] as String,
      image: json['image'] as String,
      token: foundToken, // Use the determined token
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'image': image,
      'token': token,
    };
  }

  @override
  List<Object?> get props => [
    id,
    username,
    email,
    firstName,
    lastName,
    gender,
    image,
    token,
  ];
}
