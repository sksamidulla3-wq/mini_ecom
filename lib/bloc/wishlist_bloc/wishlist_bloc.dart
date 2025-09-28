import 'dart:convert'; // For jsonEncode and jsonDecode
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import
import '../../data/models/product_model.dart';

part 'wishlist_event.dart';
part 'wishlist_state.dart';

const String _wishlistStorageKey = 'wishlist_items_v1'; // Use a versioned key

class WishlistBloc extends Bloc<WishlistEvent, WishlistState> {
  final SharedPreferences sharedPreferences; // Inject SharedPreferences

  WishlistBloc({required this.sharedPreferences}) : super(WishlistInitial()) { // Start with Initial
    on<LoadWishlist>(_onLoadWishlist);
    on<AddToWishlist>(_onAddToWishlist);
    on<RemoveFromWishlist>(_onRemoveFromWishlist);
    on<ClearWishlist>(_onClearWishlist);
  }

  Future<void> _onLoadWishlist(LoadWishlist event, Emitter<WishlistState> emit) async {
    emit(WishlistLoading());
    try {
      final List<ProductModel> loadedItems = await _loadItemsFromStorage();
      emit(WishlistLoaded(items: loadedItems));
      print("WishlistBloc: Loaded ${loadedItems.length} items from storage.");
    } catch (e) {
      emit(WishlistError("Failed to load wishlist: ${e.toString()}"));
      // Fallback to empty list on error during load
      // emit(const WishlistLoaded(items: []));
    }
  }

  void _onAddToWishlist(AddToWishlist event, Emitter<WishlistState> emit) async {
    final currentState = state;
    if (currentState is WishlistLoaded) {
      if (!currentState.items.any((item) => item.id == event.product.id)) {
        final List<ProductModel> updatedItems = List.from(currentState.items)..add(event.product);
        await _saveItemsToStorage(updatedItems); // Save after updating
        emit(WishlistLoaded(items: updatedItems));
        print("WishlistBloc: Added ${event.product.title}. Total: ${updatedItems.length}. Saved to storage.");
      } else {
        print("WishlistBloc: ${event.product.title} already in wishlist.");
      }
    } else if (currentState is WishlistInitial || currentState is WishlistLoading) {
      // If adding while not loaded, load first then add, or queue action.
      // For simplicity here, let's assume it should be loaded.
      // Or, load, then if successful, re-add the AddToWishlist event. This is more robust.
      print("WishlistBloc: Attempted to add while not loaded. Consider queuing or loading first.");
      // Example: Load and then retry (simplified)
      add(LoadWishlist()); // Trigger a load
      // Ideally, you'd have a mechanism to re-process 'event' after loading.
    }
  }

  void _onRemoveFromWishlist(RemoveFromWishlist event, Emitter<WishlistState> emit) async {
    final currentState = state;
    if (currentState is WishlistLoaded) {
      final List<ProductModel> updatedItems = currentState.items
          .where((item) => item.id != event.productId)
          .toList();
      await _saveItemsToStorage(updatedItems); // Save after updating
      emit(WishlistLoaded(items: updatedItems));
      print("WishlistBloc: Removed product ID ${event.productId}. Total: ${updatedItems.length}. Saved to storage.");
    }
  }

  void _onClearWishlist(ClearWishlist event, Emitter<WishlistState> emit) async {
    await _saveItemsToStorage([]); // Save empty list
    emit(const WishlistLoaded(items: []));
    print("WishlistBloc: Cleared wishlist. Saved to storage.");
  }

  // --- Helper methods for SharedPreferences ---

  Future<void> _saveItemsToStorage(List<ProductModel> items) async {
    try {
      // Convert List<ProductModel> to List<Map<String, dynamic>> then to List<String> of JSON
      final List<String> itemsAsJsonStringList = items
          .map((product) => jsonEncode(product.toPersistenceMap())) // Add toPersistenceMap to ProductModel
          .toList();
      await sharedPreferences.setStringList(_wishlistStorageKey, itemsAsJsonStringList);
    } catch (e) {
      print("Error saving wishlist to SharedPreferences: $e");
      // Optionally emit an error state or log more formally
    }
  }

  Future<List<ProductModel>> _loadItemsFromStorage() async {
    try {
      final List<String>? itemsAsJsonStringList = sharedPreferences.getStringList(_wishlistStorageKey);
      if (itemsAsJsonStringList == null || itemsAsJsonStringList.isEmpty) {
        return [];
      }
      // Convert List<String> of JSON back to List<ProductModel>
      return itemsAsJsonStringList
          .map((jsonString) => ProductModel.fromPersistenceMap(jsonDecode(jsonString))) // Add fromPersistenceMap to ProductModel
          .toList();
    } catch (e) {
      print("Error loading wishlist from SharedPreferences: $e");
      // If there's an error (e.g., data format changed), clear the corrupt data.
      await sharedPreferences.remove(_wishlistStorageKey);
      throw Exception("Failed to parse wishlist from storage. Storage cleared."); // Propagate error
      // return [];
    }
  }
}
