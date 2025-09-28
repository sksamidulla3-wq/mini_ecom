import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/product_bloc/product_bloc.dart';
import '../../data/models/category%20model.dart';
import '../../data/models/product_model.dart';
import '../../bloc/cart_bloc/cart_bloc.dart'; // For AddToCart event

// --- ADD IMPORT FOR WishlistBloc ---
import '../../bloc/wishlist_bloc/wishlist_bloc.dart'; // Adjust path if necessary
// --- END ADD IMPORT ---

// --- ENSURE ProductDetailScreenSimple IMPORT IS CORRECT ---

import 'detail_screen.dart';
// --- END IMPORT ---


class ProductsByCategoryScreen extends StatefulWidget {
  final CategoryModel category;

  const ProductsByCategoryScreen({
    super.key,
    required this.category,
  });

  @override
  State<ProductsByCategoryScreen> createState() =>
      _ProductsByCategoryScreenState();
}

class _ProductsByCategoryScreenState extends State<ProductsByCategoryScreen> {
  List<ProductModel>? _categoryProducts;

  @override
  void initState() {
    super.initState();
    final currentState = context.read<ProductBloc>().state;
    if (currentState is ProductsByCategoryLoaded &&
        currentState.categoryName.toLowerCase() == widget.category.name.toLowerCase()) {
      _categoryProducts = currentState.products;
    }
    _fetchProductsForCategory();
  }

  void _fetchProductsForCategory() {
    context
        .read<ProductBloc>()
        .add(FetchProductsByCategory(widget.category.name));
  }

  Future<void> _refreshProducts() async {
    _fetchProductsForCategory();
  }

  String _capitalizeWords(String input) {
    if (input.isEmpty) return "";
    return input
        .toLowerCase()
        .replaceAll('-', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final String displayCategoryName = _capitalizeWords(widget.category.name);

    return Scaffold(
      appBar: AppBar(
        title: Text(displayCategoryName),
      ),
      body: BlocConsumer<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state is ProductsByCategoryLoaded &&
              state.categoryName.toLowerCase() == widget.category.name.toLowerCase()) {
            if (mounted) {
              setState(() {
                _categoryProducts = state.products;
              });
            }
          }
        },
        builder: (context, state) {
          if (_categoryProducts != null) {
            if (_categoryProducts!.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refreshProducts,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverFillRemaining(
                      child: Center(
                        child: Text(
                          "No products found in $displayCategoryName.",
                          style: textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: _refreshProducts,
              child: _buildProductsList(context, _categoryProducts!, textTheme, colorScheme),
            );
          }

          if (state is ProductLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ProductsByCategoryLoaded &&
              state.categoryName.toLowerCase() == widget.category.name.toLowerCase()) {
            if (state.products.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refreshProducts,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverFillRemaining(
                      child: Center(
                        child: Text(
                          "No products found in $displayCategoryName.",
                          style: textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: _refreshProducts,
              child: _buildProductsList(context, state.products, textTheme, colorScheme),
            );
          } else if (state is ProductError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      "Error loading products for $displayCategoryName",
                      style: textTheme.titleLarge?.copyWith(color: Colors.red.shade700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(state.message, textAlign: TextAlign.center, style: textTheme.bodyMedium),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retry"),
                      onPressed: _refreshProducts,
                    )
                  ],
                ),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildProductsList(
      BuildContext context,
      List<ProductModel> products,
      TextTheme textTheme,
      ColorScheme colorScheme,
      ) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62, // Adjusted for potential wishlist icon space
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductItemCard(context, product, textTheme, colorScheme);
      },
    );
  }

  Widget _buildProductItemCard(
      BuildContext context,
      ProductModel product,
      TextTheme textTheme,
      ColorScheme colorScheme,
      ) {
    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreenSimple(product: product),
                  ),
                );
              },
              child: Stack( // Use Stack to overlay wishlist icon
                children: [
                  Column( // Original content: Image and Text Details
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              product.thumbnail,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(child: Icon(Icons.broken_image, size: 40, color: colorScheme.onSurfaceVariant));
                              },
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              product.title,
                              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            if (product.brand.isNotEmpty)
                              Text(
                                product.brand,
                                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.8)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  "\$${product.discountedPrice.toStringAsFixed(2)}",
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (product.discountPercentage > 0 && product.oldPrice != null) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    "\$${product.oldPrice!.toStringAsFixed(2)}",
                                    style: textTheme.labelSmall?.copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // --- ADD WISHLIST ICON BUTTON TO CARD ---
                  Positioned(
                    top: 6, // Adjust position as needed
                    right: 6, // Adjust position as needed
                    child: BlocBuilder<WishlistBloc, WishlistState>(
                      builder: (context, wishlistState) {
                        bool isInWishlist = false;
                        if (wishlistState is WishlistLoaded) {
                          isInWishlist = wishlistState.isProductInWishlist(product.id);
                        }
                        return Material(
                          color: Colors.transparent, // For InkWell splash
                          child: InkWell(
                            onTap: () {
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
                            borderRadius: BorderRadius.circular(20), // For circular splash
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.35), // Semi-transparent background
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isInWishlist ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isInWishlist ? colorScheme.error : Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // --- END WISHLIST ICON BUTTON ---
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_shopping_cart_outlined, size: 18),
              label: const Text("Add to Cart"),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
                padding: const EdgeInsets.symmetric(vertical: 8),
                textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                context.read<CartBloc>().add(AddToCart(product));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${product.title} added to cart!"),
                    backgroundColor: Colors.green.shade600,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

