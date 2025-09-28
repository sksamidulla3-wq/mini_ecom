part of 'auth_bloc.dart'; // Ensure this points to your auth_bloc.dart

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {final bool isLoggedOut; // <<< --- ADD THIS FIELD ---

// Constructor with a default value for isLoggedOut
const AuthInitial({this.isLoggedOut = false}); // <<< --- ADD CONSTRUCTOR ---

@override
List<Object?> get props => [isLoggedOut]; // <<< --- ADD TO PROPS ---
}

class AuthLoading extends AuthState {
  final bool isRestoringSession;
  final bool isLoggingOut; // <<< --- ADD THIS FIELD (OPTIONAL BUT RECOMMENDED) ---

  const AuthLoading({
    this.isRestoringSession = false,
    this.isLoggingOut = false, // <<< --- ADD TO CONSTRUCTOR ---
  });

  @override
  List<Object?> get props => [isRestoringSession, isLoggingOut]; // <<< --- ADD TO PROPS ---
}

class AuthSuccess extends AuthState {
  final UserModel user;

  const AuthSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthFailure extends AuthState {
  final String errorMessage; // Consider renaming 'error' to 'errorMessage' for clarity if you prefer

  const AuthFailure({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}

