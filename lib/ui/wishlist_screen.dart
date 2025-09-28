import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/wishlist_bloc/wishlist_bloc.dart';
import '../data/models/product_model.dart';
import '../bloc/cart_bloc/cart_bloc.dart'; // For AddToCart from wishlist
import 'detail_screen.dart'; // To navigate to product details

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Wishlist"),
        actions: [
          BlocBuilder<WishlistBloc, WishlistState>(
            builder: (context, state) {
              if (state is WishlistLoaded && state.items.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined),
                  tooltip: "Clear Wishlist",
                  onPressed: () => _showClearWishlistDialog(context, colorScheme),
                );
              }
              return const SizedBox.shrink();
            },
          )
        ],
      ),
      body: BlocBuilder<WishlistBloc, WishlistState>(
        builder: (context, state) {
          if (state is WishlistLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is WishlistLoaded) {
            if (state.items.isEmpty) {
              return _buildEmptyWishlistView(context, colorScheme, textTheme);
            }
            return _buildWishlistListView(context, state.items, textTheme, colorScheme);
          } else if (state is WishlistError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: colorScheme.error, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      "Error loading wishlist: ${state.message}",
                      style: textTheme.titleMedium?.copyWith(color: colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retry Load"),
                      onPressed: () {
                        context.read<WishlistBloc>().add(LoadWishlist());
                      },
                    )
                  ],
                ),
              ),
            );
          }
          // Default to empty view or initial loading for WishlistInitial
          // context.read<WishlistBloc>().add(LoadWishlist()); // Trigger load if in initial state
          return _buildEmptyWishlistView(context, colorScheme, textTheme);
        },
      ),
    );
  }

  void _showClearWishlistDialog(BuildContext context, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Clear Wishlist?"),
        content: const Text("Are you sure you want to remove all items from your wishlist?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
            child: Text("Clear", style: TextStyle(color: colorScheme.error)),
            onPressed: () {
              context.read<WishlistBloc>().add(ClearWishlist());
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWishlistView(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 80,
              color: colorScheme.primary.withOpacity(0.7),
            ),
            const SizedBox(height: 20),
            Text(
              "Your Wishlist is Empty",
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Tap the heart on products you love to save them here!",
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
                // Navigate to home or categories screen
                if (Navigator.canPop(context)) { // If pushed onto stack
                  Navigator.popUntil(context, (route) => route.isFirst); // Pop to first screen (usually HomeScreen)
                  // Potentially, if HomeScreen uses IndexedStack, tell it to switch to index 0
                  // This depends on your navigation setup.
                }
                // If it's a tab, you might need a different mechanism.
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistListView(
      BuildContext context,
      List<ProductModel> items,
      TextTheme textTheme,
      ColorScheme colorScheme,
      ) {
    return ListView.separated(
      padding: const EdgeInsets.all(8.0),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final product = items[index];
        return _buildWishlistItemCard(context, product, textTheme, colorScheme);
      },
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
    );
  }

  Widget _buildWishlistItemCard(
      BuildContext context,
      ProductModel product,
      TextTheme textTheme,
      ColorScheme colorScheme,
      ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreenSimple(product: product),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                product.thumbnail,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(width: 90, height: 90, color: Colors.grey.shade200, child: const Icon(Icons.broken_image, size: 30)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (product.brand.isNotEmpty)
                    Text(
                      product.brand,
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.8)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  Text(
                    "\$${product.discountedPrice.toStringAsFixed(2)}",
                    style: textTheme.bodyLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error.withOpacity(0.9), size: 26),
                  tooltip: "Remove from Wishlist",
                  onPressed: () {
                    context.read<WishlistBloc>().add(RemoveFromWishlist(product.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("${product.title} removed from wishlist."),
                        backgroundColor: colorScheme.errorContainer, // M3 themed error color
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8), // Spacer
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_shopping_cart_outlined, size: 18),
                  label: const Text("To Cart"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.secondary,
                    side: BorderSide(color: colorScheme.secondary.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    textStyle: textTheme.labelMedium,
                  ),
                  onPressed: () {
                    context.read<CartBloc>().add(AddToCart(product));
                    // Optionally remove from wishlist after adding to cart
                    // context.read<WishlistBloc>().add(RemoveFromWishlist(product.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("${product.title} added to cart."),
                        backgroundColor: Colors.green.shade600,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
