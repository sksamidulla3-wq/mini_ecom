import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/product_model.dart';
import '../../bloc/cart_bloc/cart_bloc.dart';
import '../bloc/wishlist_bloc/wishlist_bloc.dart'; // For AddToCart

class ProductDetailScreenSimple extends StatelessWidget { // Changed to StatelessWidget for simplicity
  final ProductModel product;

  const ProductDetailScreenSimple({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Determine which image to display
    String displayImageUrl = product.thumbnail; // Default to thumbnail
    if (product.images.isNotEmpty) {
      displayImageUrl = product.images.first; // Or use the first image from the list
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(product.title, style: const TextStyle(fontSize: 18)),
        actions: [
          // --- ADD WISHLIST BUTTON ---
          BlocBuilder<WishlistBloc, WishlistState>(
            builder: (context, wishlistState) {
              bool isInWishlist = false;
              if (wishlistState is WishlistLoaded) {
                isInWishlist = wishlistState.isProductInWishlist(product.id);
              }
              return IconButton(
                icon: Icon(
                  isInWishlist ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isInWishlist ? colorScheme.error : colorScheme.onSurfaceVariant,
                ),
                tooltip: isInWishlist ? "Remove from Wishlist" : "Add to Wishlist",
                onPressed: () {
                  if (isInWishlist) {
                    context.read<WishlistBloc>().add(RemoveFromWishlist(product.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${product.title} removed from wishlist."), duration: const Duration(seconds: 1)),
                    );
                  } else {
                    context.read<WishlistBloc>().add(AddToWishlist(product));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${product.title} added to wishlist!"), duration: const Duration(seconds: 1)),
                    );
                  }
                },
              );
            },
          ),
          // --- END WISHLIST BUTTON ---
        ],
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Simple Image Display
            if (displayImageUrl.isNotEmpty)
              Container(
                height: 250, // Fixed height for the image area
                width: double.infinity,
                color: Colors.grey.shade200, // Background for the image
                child: Image.network(
                  displayImageUrl,
                  fit: BoxFit.contain, // Or BoxFit.cover
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Icon(Icons.broken_image, size: 60)),
                ),
              )
            else // Fallback if no image URL is available
              Container(
                height: 250,
                width: double.infinity,
                color: Colors.grey.shade200,
                child: const Center(child: Icon(Icons.image_not_supported_outlined, size: 60)),
              ),

            // Product Details Padding
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.brand.isNotEmpty)
                    Text(
                      product.brand.toUpperCase(),
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    product.title,
                    style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildPriceSection(context, product, textTheme, colorScheme),
                  const SizedBox(height: 12),
                  _buildRatingStockSection(context, product, textTheme, colorScheme),
                  const Divider(height: 32, thickness: 1),
                  Text(
                    "Description",
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildAddToCartBottomBar(context, product, textTheme, colorScheme),
    );
  }

  // Helper methods are now static or could be part of the StatelessWidget
  // if they don't rely on `widget.product` directly but receive product as a parameter.

  Widget _buildPriceSection(BuildContext context, ProductModel product, TextTheme textTheme, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          "\$${product.discountedPrice.toStringAsFixed(2)}",
          style: textTheme.headlineMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (product.oldPrice != null && product.discountPercentage > 0) ...[
          const SizedBox(width: 10),
          Text(
            "\$${product.oldPrice!.toStringAsFixed(2)}",
            style: textTheme.titleMedium?.copyWith(
              decoration: TextDecoration.lineThrough,
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "${product.discountPercentage.toStringAsFixed(0)}% OFF",
              style: textTheme.labelMedium?.copyWith(
                color: Colors.green.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRatingStockSection(BuildContext context, ProductModel product, TextTheme textTheme, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 22),
        const SizedBox(width: 4),
        Text(
          "${product.rating.toStringAsFixed(1)}",
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text( // Using generic text as product model doesn't have review count
          " (User Rating)",
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const Spacer(),
        Text(
          product.stock > 0 ? "In Stock (${product.stock})" : "Out of Stock",
          style: textTheme.bodyMedium?.copyWith(
            color: product.stock > 0 ? Colors.green.shade700 : colorScheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAddToCartBottomBar(BuildContext context, ProductModel product, TextTheme textTheme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0)
          .copyWith(bottom: MediaQuery.of(context).padding.bottom + 12.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        border: Border(top: BorderSide(color: colorScheme.outline.withOpacity(0.2))),
      ),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add_shopping_cart_outlined),
        label: const Text("Add to Cart"),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
        ),
        onPressed: product.stock > 0
            ? () {
          context.read<CartBloc>().add(AddToCart(product));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${product.title} added to cart!"),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
            : null,
      ),
    );
  }
}
