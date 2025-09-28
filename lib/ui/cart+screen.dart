

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cart_bloc/cart_bloc.dart';
import '../data/models/cart model.dart';
import 'homescreen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Cart"),
        // elevation: 0, // Optional
        actions: [
          // Clear Cart Button
          BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              if (state is CartLoaded && state.items.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.remove_shopping_cart_outlined),
                  tooltip: "Clear Cart",
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text("Clear Cart?"),
                        content: const Text(
                            "Are you sure you want to remove all items from your cart?"),
                        actions: [
                          TextButton(
                            child: const Text("Cancel"),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                          TextButton(
                            child: Text("Clear", style: TextStyle(color: colorScheme.error)),
                            onPressed: () {
                              context.read<CartBloc>().add(ClearCart());
                              Navigator.of(dialogContext).pop();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          )
        ],
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          // CORRECTED ORDER OF CHECKS:
          if (state is CartLoaded) { // Check for CartLoaded FIRST
            if (state.items.isEmpty) {
              return _buildEmptyCartView(context, colorScheme, textTheme);
            }
            return _buildCartListView(context, state, textTheme, colorScheme);
          } else if (state is CartLoading) { // THEN check for CartLoading
            return const Center(child: CircularProgressIndicator());
          } else if (state is CartError) {
            return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: colorScheme.error, size: 48),
                        const SizedBox(height: 16),
                        Text("Error loading cart: ${state.message}",
                          style: textTheme.titleMedium?.copyWith(color: colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text("Retry Load"),
                            onPressed: (){
                              context.read<CartBloc>().add(LoadCart()); // Assuming LoadCart event exists
                            }
                        )
                      ]),
                ));
          }
          // Default to empty cart view if CartInitial or any other unexpected state
          return _buildEmptyCartView(context, colorScheme, textTheme);
        },
      ),
    );
  }

  Widget _buildEmptyCartView(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: colorScheme.primary.withOpacity(0.7),
            ),
            const SizedBox(height: 20),
            Text(
              "Your Cart is Empty",
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Looks like you haven't added anything yet. Explore products and fill it up!",
              style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.explore_outlined),
              label: const Text("Explore Products"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (ctx)=> HomeScreen()));
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCartListView(
      BuildContext context,
      CartLoaded cartState,
      TextTheme textTheme,
      ColorScheme colorScheme,
      ) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated( // Using separated for dividers
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            itemCount: cartState.items.length,
            itemBuilder: (context, index) {
              final cartItem = cartState.items[index];
              return _buildCartItemCard(context, cartItem, textTheme, colorScheme);
            },
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
          ),
        ),
        _buildCartSummary(context, cartState, textTheme, colorScheme),
      ],
    );
  }

  Widget _buildCartItemCard(
      BuildContext context,
      CartItemModel cartItem,
      TextTheme textTheme,
      ColorScheme colorScheme,
      ) {
    return Padding( // Removed Card for a flatter list item look, using Padding and InkWell
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              cartItem.product.thumbnail,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(width: 80, height: 80, color: Colors.grey.shade200, child: const Icon(Icons.broken_image, size: 30)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.product.title,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "\$${cartItem.product.discountedPrice.toStringAsFixed(2)}",
                  style: textTheme.bodyLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildQuantityButton(
                      context,
                      icon: Icons.remove_circle_outline,
                      onPressed: cartItem.quantity > 1
                          ? () => context.read<CartBloc>().add(UpdateCartItemQuantity(cartItem.product.id, cartItem.quantity - 1))
                          : () => context.read<CartBloc>().add(RemoveFromCart(cartItem.product.id)),
                      color: cartItem.quantity > 1 ? colorScheme.primary : colorScheme.error,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(cartItem.quantity.toString(), style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    _buildQuantityButton(
                      context,
                      icon: Icons.add_circle_outline,
                      onPressed: () => context.read<CartBloc>().add(UpdateCartItemQuantity(cartItem.product.id, cartItem.quantity + 1)),
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: colorScheme.error.withOpacity(0.8), size: 26),
            tooltip: "Remove Item",
            onPressed: () {
              context.read<CartBloc>().add(RemoveFromCart(cartItem.product.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("${cartItem.product.title} removed."),
                  backgroundColor: colorScheme.errorContainer,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton(BuildContext context,
      {required IconData icon, required VoidCallback onPressed, required Color color}) {
    return InkWell( // Using InkWell for larger tap area if needed
      onTap: onPressed,
      customBorder: const CircleBorder(), // Makes tap feedback circular
      child: Padding(
        padding: const EdgeInsets.all(4.0), // Padding around the icon itself
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }

  Widget _buildCartSummary(
      BuildContext context,
      CartLoaded cartState,
      TextTheme textTheme,
      ColorScheme colorScheme,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      decoration: BoxDecoration(
        color: colorScheme.surface, // Use surface color
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        // border: Border(top: BorderSide(color: colorScheme.outline.withOpacity(0.5))) // Optional top border
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Subtotal (${cartState.totalItemsCount} items)", style: textTheme.titleMedium),
              Text(
                "\$${cartState.subtotal.toStringAsFixed(2)}",
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Divider(), // Optional divider
          // const SizedBox(height: 8),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     Text("Total:", style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          //     Text(
          //       "\$${cartState.total.toStringAsFixed(2)}",
          //       style: textTheme.headlineSmall?.copyWith(
          //           fontWeight: FontWeight.bold, color: colorScheme.primary),
          //     ),
          //   ],
          // ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: cartState.items.isNotEmpty
                ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Proceed to Checkout (not implemented)")),
              );
              // TODO: Navigate to Checkout Screen
            }
                : null,
            child: Text("Proceed to Checkout (\$${cartState.total.toStringAsFixed(2)})", style: textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
