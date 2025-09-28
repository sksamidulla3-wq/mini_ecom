part of 'signup_bloc.dart';

abstract class SignUpEvent extends Equatable {
  const SignUpEvent();

  @override
  List<Object> get props => [];
}

class SignUpUserRequested extends SignUpEvent {
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String password;

  const SignUpUserRequested({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [firstName, lastName, username, email, password];
}

