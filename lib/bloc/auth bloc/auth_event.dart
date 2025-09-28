part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String username;
  final String password;
  final int? expiresInMins; // This is for the dummyjson.com/auth/login endpoint

  const LoginRequested({
    required this.username,
    required this.password,
    this.expiresInMins, // Optional
  });

  @override
  List<Object?> get props => [username, password, expiresInMins];
}

class LogoutRequested extends AuthEvent {

}

class LoadUserFromSession extends AuthEvent {
  final UserModel user;
  const LoadUserFromSession(this.user);
  @override
  List<Object?> get props => [user];
}

// --- ADD THIS EVENT ---
class CheckInitialAuthStatus extends AuthEvent {}
// --- END ---
