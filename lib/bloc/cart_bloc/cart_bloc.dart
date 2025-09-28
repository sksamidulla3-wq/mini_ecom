import 'dart:convert'; // For jsonEncode and jsonDecode

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import '../../data/models/cart_model.dart'; // Assuming CartLoaded holds items directly
import '../../data/models/cart model.dart'; // Ensure this model has toJson/fromJson
import '../../data/models/product_model.dart';   // Ensure this model has toJson/fromJson

part 'cart_event.dart';
part 'cart_state.dart';

const String _cartPrefsKey = 'user_cart_items_v1'; // Key for SharedPreferences

class CartBloc extends Bloc<CartEvent, CartState> {
  final SharedPreferences _sharedPreferences;

  CartBloc({required SharedPreferences sharedPreferences})
      : _sharedPreferences = sharedPreferences,
        super(CartInitial()) { // Start with CartInitial, LoadCart will populate
    on<LoadCart>(_onLoadCart);
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<UpdateCartItemQuantity>(_onUpdateCartItemQuantity);
    on<ClearCart>(_onClearCart);

    // Dispatch LoadCart initially to load persisted cart
    // This is often done when the BLoC is created in main.dart
    // add(LoadCart()); // If you want to auto-load.
  }

  Future<void> _saveCartToPrefs(List<CartItemModel> items) async {
    try {
      final List<String> cartItemsJson =
      items.map((item) => jsonEncode(item.toJson())).toList();
      await _sharedPreferences.setStringList(_cartPrefsKey, cartItemsJson);
      print("CartBloc: Cart saved to SharedPreferences. Items: ${items.length}");
    } catch (e) {
      print("CartBloc: Error saving cart to SharedPreferences: ${e.toString()}");
      // Optionally emit an error state or handle it
    }
  }

  Future<List<CartItemModel>> _loadCartFromPrefs() async {
    try {
      final List<String>? cartItemsJson =
      _sharedPreferences.getStringList(_cartPrefsKey);
      if (cartItemsJson != null) {
        final items = cartItemsJson
            .map((itemJson) =>
            CartItemModel.fromJson(jsonDecode(itemJson) as Map<String, dynamic>))
            .toList();
        print("CartBloc: Cart loaded from SharedPreferences. Items: ${items.length}");
        return items;
      }
    } catch (e) {
      print("CartBloc: Error loading cart from SharedPreferences: ${e.toString()}");
      // Could happen if JSON is corrupted or model changed
      // Clearing corrupted data:
      // await _sharedPreferences.remove(_cartPrefsKey);
    }
    return []; // Return empty list if nothing found or error
  }

  Future<void> _onLoadCart(LoadCart event, Emitter<CartState> emit) async {
    emit(CartLoading());
    try {
      final List<CartItemModel> loadedItems = await _loadCartFromPrefs();
      emit(CartLoaded(items: loadedItems));
    } catch (e) {
      emit(CartError("Failed to load cart: ${e.toString()}"));
    }
  }

  Future<void> _onAddToCart(AddToCart event, Emitter<CartState> emit) async {
    final currentState = state;
    List<CartItemModel> updatedItems = [];

    if (currentState is CartLoaded) {
      updatedItems = List.from(currentState.items);
    } else if (currentState is CartInitial) {
      // If initial, updatedItems is already empty, which is fine.
    } else if (currentState is CartLoading) {
      print("CartBloc: Cart is loading, AddToCart event might be queued or handled later.");
      // For simplicity, we'll try to proceed, but ideally, wait or queue.
      // Attempt to load current items if possible, or start fresh
      updatedItems = await _loadCartFromPrefs();
    } else if (currentState is CartError) {
      // If in error state, maybe try to recover by loading from prefs
      updatedItems = await _loadCartFromPrefs();
    }


    final existingItemIndex =
    updatedItems.indexWhere((item) => item.product.id == event.product.id);

    if (existingItemIndex != -1) {
      final existingItem = updatedItems[existingItemIndex];
      updatedItems[existingItemIndex] =
          existingItem.copyWith(quantity: existingItem.quantity + 1);
    } else {
      updatedItems.add(CartItemModel(product: event.product, quantity: 1));
    }

    await _saveCartToPrefs(updatedItems);
    emit(CartLoaded(items: updatedItems));
  }

  Future<void> _onRemoveFromCart(RemoveFromCart event, Emitter<CartState> emit) async {
    final currentState = state;
    if (currentState is CartLoaded) {
      List<CartItemModel> updatedItems = List.from(currentState.items);
      updatedItems.removeWhere((item) => item.product.id == event.productId);
      await _saveCartToPrefs(updatedItems);
      emit(CartLoaded(items: updatedItems));
    } else {
      print("CartBloc: Cannot remove from cart, state is not CartLoaded.");
      // Optionally load and then attempt removal if robust handling is needed
    }
  }

  Future<void> _onUpdateCartItemQuantity(
      UpdateCartItemQuantity event, Emitter<CartState> emit) async {
    final currentState = state;
    if (currentState is CartLoaded) {
      List<CartItemModel> updatedItems = List.from(currentState.items);
      final itemIndex =
      updatedItems.indexWhere((item) => item.product.id == event.productId);

      if (itemIndex != -1) {
        if (event.newQuantity > 0) {
          final existingItem = updatedItems[itemIndex];
          updatedItems[itemIndex] =
              existingItem.copyWith(quantity: event.newQuantity);
        } else {
          updatedItems.removeAt(itemIndex);
        }
        await _saveCartToPrefs(updatedItems);
        emit(CartLoaded(items: updatedItems));
      }
    } else {
      print("CartBloc: Cannot update quantity, state is not CartLoaded.");
    }
  }

  Future<void> _onClearCart(ClearCart event, Emitter<CartState> emit) async {
    await _sharedPreferences.remove(_cartPrefsKey); // Remove from prefs
    print("CartBloc: Cart cleared from SharedPreferences.");
    emit(const CartLoaded(items: []));
  }
}

