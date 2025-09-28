// lib/bloc/cart_bloc/cart_state.dart
part of 'cart_bloc.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object> get props => [];
}

class CartInitial extends CartState {} // You might not even need this if starting with CartLoaded

class CartLoading extends CartState {} // Generic loading state

class CartLoaded extends CartState {
  final List<CartItemModel> items;

  const CartLoaded({this.items = const []}); // Default to empty list

  // Factory constructor for convenience if you were using it before
  // CartLoaded.fromItems(List<CartItemModel> items) : this(items: List.from(items));

  // Calculated properties
  int get totalItemsCount => items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => items.fold(0.0, (sum, item) => sum + (item.product.discountedPrice * item.quantity));
  double get total => subtotal; // For now, total is same as subtotal  @override
  List<Object> get props => [items, totalItemsCount, subtotal, total]; // Include calculated properties if they define the state
}

class CartError extends CartState {
  final String message;
  const CartError(this.message);

  @override
  List<Object> get props => [message];
}
