part of 'wishlist_bloc.dart';

abstract class WishlistState extends Equatable {
  const WishlistState();

  @override
  List<Object> get props => [];
}

class WishlistInitial extends WishlistState {} // Or WishlistLoading if auto-loading

class WishlistLoading extends WishlistState {}

class WishlistLoaded extends WishlistState {
  final List<ProductModel> items;
  const WishlistLoaded({this.items = const []});

  @override
  List<Object> get props => [items];

  // Helper to check if a product is in the wishlist
  bool isProductInWishlist(int productId) {
    return items.any((item) => item.id == productId);
  }
}

class WishlistError extends WishlistState {
  final String message;
  const WishlistError(this.message);

  @override
  List<Object> get props => [message];
}
