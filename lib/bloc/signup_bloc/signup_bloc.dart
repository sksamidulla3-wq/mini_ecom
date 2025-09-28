import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Ensure correct paths for your project structure
// You might not need UserModel here if SignUpSuccess just carries a message
// import '../../data/models/user_model.dart';
import '../../data/remote/api_helper.dart';
import '../../data/remote/app_exceptions.dart';

part 'signup_event.dart';
part 'signup_state.dart';

class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  final ApiHelper _apiHelper;

  SignUpBloc({required ApiHelper apiHelper})
      : _apiHelper = apiHelper,
        super(SignUpInitial()) {
    on<SignUpUserRequested>(_onSignUpUserRequested);
  }

  Future<void> _onSignUpUserRequested(
      SignUpUserRequested event, Emitter<SignUpState> emit) async {
    emit(SignUpLoading());
    try {
      final Map<String, dynamic> requestBody = {
        "firstName": event.firstName,
        "lastName": event.lastName,
        "username": event.username,
        "email": event.email,
        "password": event.password, // Dummy API won't use this for auth
      };

      print(
          "SignUpBloc: Sending sign-up request with body: ${jsonEncode(requestBody)}");

      // Using dummyjson.com/users/add for simulation
      final dynamic responseData = await _apiHelper.postApi(
        "users/add",
        requestBody,
      );

      print("SignUpBloc: Sign-up API response: $responseData");

      // Assuming success if no error and responseData is not null/empty
      // A real API would give a more definitive success response
      if (responseData != null) { // Basic check for dummy API
        emit(const SignUpSuccess());
      } else {
        emit(const SignUpFailure(errorMessage: "Failed to create user. Empty response from server."));
      }

    } on AppException catch (e) {
      print("SignUpBloc Error (AppException): ${e.toString()} URL: ${e.url}");
      emit(SignUpFailure(errorMessage: e.toString()));
    } catch (e, stackTrace) {
      print("SignUpBloc Error (Unknown): ${e.toString()}");
      print("SignUpBloc StackTrace: $stackTrace");
      emit(SignUpFailure(
          errorMessage: "An unexpected error occurred during sign-up: ${e.toString()}"));
    }
  }
}

