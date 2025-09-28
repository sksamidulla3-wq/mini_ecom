part of 'signup_bloc.dart';

abstract class SignUpState extends Equatable {
  const SignUpState();

  @override
  List<Object> get props => [];
}

class SignUpInitial extends SignUpState {} // Initial state before any action

class SignUpLoading extends SignUpState {} // User is being signed up

class SignUpSuccess extends SignUpState {
  // You could pass the "created" user or a success message if needed
  // final UserModel createdUser;
  final String successMessage;
  const SignUpSuccess({this.successMessage = "Account created successfully! Please log in."});

  @override
  List<Object> get props => [successMessage];
}

class SignUpFailure extends SignUpState {
  final String errorMessage;
  const SignUpFailure({required this.errorMessage});

  @override
  List<Object> get props => [errorMessage];
}