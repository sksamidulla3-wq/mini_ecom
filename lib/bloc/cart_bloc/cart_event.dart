part of 'cart_bloc.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object> get props => [];
}

// Optional: If you plan to load the cart from storage initially
class LoadCart extends CartEvent {}

class AddToCart extends CartEvent {
  final ProductModel product;

  const AddToCart(this.product);

  @override
  List<Object> get props => [product];
}

// --- DEFINE MISSING EVENTS ---

class RemoveFromCart extends CartEvent {
  final int productId; // Assuming product ID is an int

  const RemoveFromCart(this.productId);

  @override
  List<Object> get props => [productId];
}

class UpdateCartItemQuantity extends CartEvent {
  final int productId;
  final int newQuantity;

  const UpdateCartItemQuantity(this.productId, this.newQuantity);

  @override
  List<Object> get props => [productId, newQuantity];
}

class ClearCart extends CartEvent {}
