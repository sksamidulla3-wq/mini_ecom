import 'dart:async';
import 'dart:convert'; // For jsonEncode/Decode

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/user_model.dart';
import '../../data/remote/api_helper.dart';
import '../../data/remote/app_exceptions.dart';

part 'auth_event.dart';
part 'auth_state.dart';

// SharedPreferences Keys (ensure these match your auth_state.dart if modified there)
const String _isLoggedInKey = 'auth_isLoggedIn_status';
const String _userTokenKey = 'auth_userToken';
const String _userIdKey = 'auth_userId';
const String _userUsernameKey = 'auth_userUsername';
const String _userEmailKey = 'auth_userEmail';
const String _userFirstNameKey = 'auth_userFirstName';
const String _userLastNameKey = 'auth_userLastName';
const String _userGenderKey = 'auth_userGender';
const String _userImageKey = 'auth_userImage';


class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiHelper _apiHelper; // ApiHelper is still needed for login
  final SharedPreferences _sharedPreferences;

  AuthBloc({
    required ApiHelper apiHelper,
    required SharedPreferences sharedPreferences,
  })  : _apiHelper = apiHelper,
        _sharedPreferences = sharedPreferences,
        super(const AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckInitialAuthStatus>(_onCheckInitialAuthStatus);
    on<LoadUserFromSession>(_onLoadUserFromSession);
  }

  Future<void> _onCheckInitialAuthStatus(
      CheckInitialAuthStatus event, Emitter<AuthState> emit) async {
    print("AuthBloc: _onCheckInitialAuthStatus STARTED.");
    emit(const AuthLoading(isRestoringSession: true));

    try {
      final bool isLoggedIn = _sharedPreferences.getBool(_isLoggedInKey) ?? false;
      print("AuthBloc: isLoggedIn from SharedPreferences: $isLoggedIn");

      if (isLoggedIn) {
        final token = _sharedPreferences.getString(_userTokenKey);
        if (token == null || token.isEmpty) {
          print("AuthBloc: isLoggedIn was true, but token is missing. Clearing session.");
          await _clearUserSessionInternal();
          emit(const AuthInitial(isLoggedOut: true));
          return;
        }

        final user = UserModel(
          id: _sharedPreferences.getInt(_userIdKey) ?? 0,
          username: _sharedPreferences.getString(_userUsernameKey) ?? '',
          email: _sharedPreferences.getString(_userEmailKey) ?? '',
          firstName: _sharedPreferences.getString(_userFirstNameKey) ?? '',
          lastName: _sharedPreferences.getString(_userLastNameKey) ?? '',
          gender: _sharedPreferences.getString(_userGenderKey) ?? '',
          image: _sharedPreferences.getString(_userImageKey) ?? '',
          token: token,
        );

        if (user.id == 0 || user.email.isEmpty) {
          print("AuthBloc: User data seems incomplete/invalid. Clearing session.");
          await _clearUserSessionInternal();
          emit(const AuthInitial(isLoggedOut: true));
          return;
        }
        // NO _apiHelper.setAuthToken(user.token); as ApiHelper is stateless
        print("AuthBloc: Session restored for ${user.email}. EMITTING AuthSuccess.");
        emit(AuthSuccess(user: user));
      } else {
        print("AuthBloc: No active session. EMITTING AuthInitial(isLoggedOut: true).");
        emit(const AuthInitial(isLoggedOut: true));
      }
    } catch (e, stackTrace) {
      print("AuthBloc: ERROR in _onCheckInitialAuthStatus: $e\n$stackTrace");
      await _clearUserSessionInternal();
      print("AuthBloc: EMITTING AuthFailure due to error in session check.");
      emit(AuthFailure(errorMessage: "Failed to check session: ${e.toString()}"));
    }
    print("AuthBloc: _onCheckInitialAuthStatus FINISHED.");
  }

  void _onLoadUserFromSession(
      LoadUserFromSession event, Emitter<AuthState> emit) {
    print("AuthBloc: _onLoadUserFromSession for ${event.user.email}. EMITTING AuthSuccess.");
    // NO _apiHelper.setAuthToken(event.user.token);
    emit(AuthSuccess(user: event.user));
  }

  Future<void> _onLoginRequested(
      LoginRequested event, Emitter<AuthState> emit) async {
    print("AuthBloc: _onLoginRequested for ${event.username}");
    emit(const AuthLoading());
    try {
      final Map<String, dynamic> requestBody = {
        "username": event.username,
        "password": event.password,
      };
      // Example for dummyjson.com which takes 'expiresInMins'
      // if (event.expiresInMins != null) {
      // requestBody["expiresInMins"] = event.expiresInMins;
      // }

      print("AuthBloc: Sending login request with body: ${jsonEncode(requestBody)}");

      final dynamic responseData = await _apiHelper.postApi(
        "https://dummyjson.com/auth/login", // Example API
        requestBody,
        isFullUrl: true, // Assuming login is a full URL
      );

      print("AuthBloc: Full responseData from login: $responseData");
      final UserModel loggedInUser =
      UserModel.fromJson(responseData as Map<String, dynamic>);

      print("AuthBloc: Login successful for ${loggedInUser.email}. Token: ${loggedInUser.token}");
      await _saveUserSession(loggedInUser); // Saves token to SharedPreferences
      // NO _apiHelper.setAuthToken(loggedInUser.token);

      print("AuthBloc: User session saved. EMITTING AuthSuccess.");
      emit(AuthSuccess(user: loggedInUser));
    } on AppException catch (e) {
      print("AuthBloc Error (AppException) during login: ${e.toString()} URL: ${e.url}");
      emit(AuthFailure(errorMessage: e.toString()));
    } catch (e, stackTrace) {
      print("AuthBloc Error (Unknown) during login: ${e.toString()}");
      print("AuthBloc StackTrace: $stackTrace");
      emit(AuthFailure(errorMessage: "An unexpected error occurred: ${e.toString()}"));
    }
  }

  Future<void> _onLogoutRequested(
      LogoutRequested event, Emitter<AuthState> emit) async {
    print("AuthBloc: _onLogoutRequested STARTED.");
    emit(const AuthLoading(isLoggingOut: true));

    await _clearUserSessionInternal(); // Clears token from SharedPreferences
    // NO _apiHelper.clearAuthToken();

    print("AuthBloc: User session cleared. EMITTING AuthInitial(isLoggedOut: true).");
    emit(const AuthInitial(isLoggedOut: true));
    print("AuthBloc: _onLogoutRequested FINISHED.");
  }

  Future<void> _saveUserSession(UserModel user) async {
    print("AuthBloc: Saving user session for ${user.email}");
    await _sharedPreferences.setBool(_isLoggedInKey, true);
    await _sharedPreferences.setString(_userTokenKey, user.token); // Token is saved here
    await _sharedPreferences.setInt(_userIdKey, user.id);
    await _sharedPreferences.setString(_userFirstNameKey, user.firstName);
    await _sharedPreferences.setString(_userLastNameKey, user.lastName);
    await _sharedPreferences.setString(_userEmailKey, user.email);
    await _sharedPreferences.setString(_userImageKey, user.image);
    await _sharedPreferences.setString(_userUsernameKey, user.username);
    await _sharedPreferences.setString(_userGenderKey, user.gender);
    print("AuthBloc: User session saved to SharedPreferences.");
  }

  Future<void> _clearUserSessionInternal() async {
    print("AuthBloc: Clearing user session from SharedPreferences.");
    await _sharedPreferences.remove(_isLoggedInKey);
    await _sharedPreferences.remove(_userTokenKey); // Token is cleared here
    await _sharedPreferences.remove(_userIdKey);
    await _sharedPreferences.remove(_userFirstNameKey);
    await _sharedPreferences.remove(_userLastNameKey);
    await _sharedPreferences.remove(_userEmailKey);
    await _sharedPreferences.remove(_userImageKey);
    await _sharedPreferences.remove(_userUsernameKey);
    await _sharedPreferences.remove(_userGenderKey);
    print("AuthBloc: User session cleared from SharedPreferences.");
  }
}
