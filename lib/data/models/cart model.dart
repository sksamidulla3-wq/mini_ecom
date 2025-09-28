import 'package:equatable/equatable.dart';import 'dart:convert'; // For json if you store the whole ProductModel as JSON string
import 'product_model.dart'; // Your ProductModel

class CartItemModel extends Equatable { // Or CartItem if that's the actual class name
  final ProductModel product;
  final int quantity;

  const CartItemModel({required this.product, required this.quantity});

  CartItemModel copyWith({
    ProductModel? product,
    int? quantity,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  // --- METHODS FOR PERSISTENCE ---
  Map<String, dynamic> toJson() {
    return {
      'product': product.toPersistenceMap(), // Uses ProductModel's method
      'quantity': quantity,
    };
  }

  factory CartItemModel.fromJson(Map<String, dynamic> map) {
    return CartItemModel(
      product: ProductModel.fromPersistenceMap(map['product'] as Map<String, dynamic>),
      quantity: map['quantity'] as int,
    );
  }
  // --- END METHODS FOR PERSISTENCE ---

  @override
  List<Object?> get props => [product, quantity];
}

