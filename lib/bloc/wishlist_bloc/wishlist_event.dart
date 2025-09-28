part of 'wishlist_bloc.dart';

abstract class WishlistEvent extends Equatable {
  const WishlistEvent();

  @override
  List<Object> get props => [];
}

class LoadWishlist extends WishlistEvent {} // To load from storage (if implemented)

class AddToWishlist extends WishlistEvent {
  final ProductModel product;
  const AddToWishlist(this.product);

  @override
  List<Object> get props => [product];
}

class RemoveFromWishlist extends WishlistEvent {
  final int productId; // Use product ID to remove
  const RemoveFromWishlist(this.productId);

  @override
  List<Object> get props => [productId];
}

class ClearWishlist extends WishlistEvent {}
