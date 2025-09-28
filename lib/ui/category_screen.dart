import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_ecom/ui/productcategory_screen.dart';
import '../../bloc/product_bloc/product_bloc.dart';
import '../../data/models/category%20model.dart';

class CategoriesScreen extends StatefulWidget { // Changed to StatefulWidget
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> { // Create State
  List<CategoryModel>? _allCategories; // Store categories locally in the state

  @override
  void initState() {
    super.initState();
    // Check if categories are already available from ProductBloc's current state
    final currentState = context.read<ProductBloc>().state;
    if (currentState is ProductHomeDataLoaded) {
      _allCategories = currentState.categories;
    } else if (_allCategories == null) {
      // If not loaded, and not available, trigger a fetch.
      // This ensures if this screen is opened directly or ProductHomeDataLoaded hasn't occurred,
      // categories are fetched.
      // However, this might trigger a redundant fetch if HomeScreen already did it.
      // A better approach might be to ensure ProductHomeDataLoaded is emitted by default from HomeScreen's init.
      // For now, let's keep it simple:
      // context.read<ProductBloc>().add(FetchHomeData()); // Potentially redundant
    }
  }

  IconData _getIconForCategory(String categoryName) {
    // ... (your existing _getIconForCategory method)
    switch (categoryName.toLowerCase()) {
      case 'smartphones':
        return Icons.phone_android;
      case 'laptops':
        return Icons.laptop_mac;
      case 'fragrances':
        return Icons.style_outlined;
      case 'skincare':
        return Icons.spa_outlined;
      case 'groceries':
        return Icons.local_grocery_store;
      case 'home-decoration':
        return Icons.home_work_outlined;
      case 'furniture':
        return Icons.chair_outlined;
      case 'tops':
      case 'womens-dresses':
      case 'womens-shoes':
      case 'mens-shirts':
      case 'mens-shoes':
      case 'mens-watches':
      case 'womens-watches':
      case 'womens-bags':
      case 'womens-jewellery':
        return Icons.checkroom;
      case 'sunglasses':
        return Icons.wb_sunny_outlined;
      case 'automotive':
        return Icons.directions_car_outlined;
      case 'motorcycle':
        return Icons.motorcycle_outlined;
      case 'lighting':
        return Icons.lightbulb_outline;
      default:
        return Icons.category;
    }
  }

  Future<void> _refreshCategories() async {
    // Dispatch event to re-fetch all data, including categories
    context.read<ProductBloc>().add(FetchHomeData());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Categories"),
      ),
      body: BlocConsumer<ProductBloc, ProductState>( // Use BlocConsumer
        listener: (context, state) {
          // If ProductHomeDataLoaded occurs, update our local _allCategories
          if (state is ProductHomeDataLoaded) {
            setState(() {
              _allCategories = state.categories;
            });
          }
        },
        builder: (context, state) {
          // Priority 1: Use locally stored categories if available
          if (_allCategories != null && _allCategories!.isNotEmpty) {
            return RefreshIndicator( // Added RefreshIndicator
              onRefresh: _refreshCategories,
              child: _buildCategoriesGrid(context, _allCategories!, textTheme, colorScheme),
            );
          }

          // Priority 2: Handle current BLoC states for initial load or errors
          if (state is ProductLoading && _allCategories == null) { // Only show global loading if we have no categories yet
            return const Center(child: CircularProgressIndicator());
          } else if (state is ProductHomeDataLoaded) {
            // This case handles the initial successful load if _allCategories wasn't set by listener yet
            if (state.categories.isEmpty) {
              return const Center(child: Text("No categories found."));
            }
            // No need to call setState here, _allCategories will be set by listener
            return RefreshIndicator(
              onRefresh: _refreshCategories,
              child: _buildCategoriesGrid(context, state.categories, textTheme, colorScheme),
            );
          } else if (state is ProductError && _allCategories == null) { // Show error only if we have no categories
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: colorScheme.error, size: 40),
                    const SizedBox(height: 10),
                    Text(
                      "Error loading categories: ${state.message}",
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(color: colorScheme.error),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retry"),
                      onPressed: _refreshCategories,
                    )
                  ],
                ),
              ),
            );
          }

          // Fallback if no categories are stored and current state isn't helping immediately
          // This might briefly show if navigating back and ProductHomeDataLoaded is not the immediate state
          // and _allCategories hasn't been updated by the listener yet.
          if (state is ProductsByCategoryLoaded && _allCategories == null) {
            // We are on category screen, but main categories aren't loaded into _allCategories yet.
            // This indicates a need to fetch home data.
            return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Loading category list..."),
                    const SizedBox(height: 10),
                    // Optionally trigger a fetch if it seems they were never loaded
                    // This can be aggressive, ensure ProductHomeData is fetched reliably once.
                    // ElevatedButton(onPressed: _refreshCategories, child: const Text("Load Categories"))
                    const CircularProgressIndicator(),
                  ],
                )
            );
          }


          // Default fallback:
          return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Loading categories or no categories found."),
                  const SizedBox(height: 10),
                  ElevatedButton(onPressed: _refreshCategories, child: const Text("Reload All Data"))
                ],
              )
          );
        },
      ),
    );
  }

  Widget _buildCategoriesGrid(
      BuildContext context,
      List<CategoryModel> categories,
      TextTheme textTheme,
      ColorScheme colorScheme,
      ) {
    // Make sure the GridView is scrollable if RefreshIndicator is its direct parent.
    // If GridView.builder is inside another non-scrollable widget, wrap GridView in CustomScrollView
    // or ensure it's the primary scrollable.
    return GridView.builder(
      // For RefreshIndicator to work directly with GridView, GridView must be the primary scrollable view.
      // If it's part of a larger scroll view, RefreshIndicator should wrap that larger view.
      // physics: const AlwaysScrollableScrollPhysics(), // Ensures it's scrollable even with few items
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 0.95,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return InkWell(
          onTap: () {
            print("Navigating to products for category: ${category.name}");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductsByCategoryScreen(category: category),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12.0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      _getIconForCategory(category.name),
                      size: 36,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(6.0, 0, 6.0, 10.0),
                  child: Text(
                    category.name.replaceAll('-', ' ').split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' '),
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
