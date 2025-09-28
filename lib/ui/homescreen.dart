import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';import 'package:mini_ecom/ui/productcategory_screen.dart';
import 'package:mini_ecom/ui/profileScreen.dart';
import 'package:mini_ecom/ui/theme_provider/themeProvider.dart';
import 'package:provider/provider.dart';

// --- ADD IMPORT FOR WishlistBloc ---
import '../bloc/wishlist_bloc/wishlist_bloc.dart'; // Adjust path if necessary
// --- END ADD IMPORT ---
// --- END IMPORT ---

// Adjust import paths based on your actual project structure
import '../../data/models/user_model.dart';
import '../../data/models/product_model.dart';
import '../bloc/auth%20bloc/auth_bloc.dart';
import '../bloc/cart_bloc/cart_bloc.dart';
import '../bloc/product_bloc/product_bloc.dart';
import '../data/models/category%20model.dart';
import 'cart+screen.dart'; // Corrected import
import 'category_screen.dart';
// import 'detail_screen.dart'; // Assuming you replaced this with ProductDetailScreenSimple for this flow
import 'detail_screen.dart';
import 'onboarding/login.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentBottomNavIndex = 0;
  int _currentPageViewBannerIndex = 0;
  final PageController _bannerPageController = PageController();

  late List<Widget> _pages;
  bool _isPagesInitialized = false;

  List<CategoryModel>? _homeScreenCategories;
  List<ProductModel>? _homeScreenFeaturedProducts;

  @override
  void initState() {
    super.initState();
    // ProductBloc provider in main.dart already dispatches FetchHomeData.
  }

  void _initializePages() {
    if (!_isPagesInitialized) {
      _pages = [
        _buildHomePageContentContainer(),
        const CategoriesScreen(),
        const CartScreen(),
        const ProfileScreen(),
      ];
      _isPagesInitialized = true;
    }
  }

  @override
  void dispose() {
    _bannerPageController.dispose();
    super.dispose();
  }

  Future<void> _refreshHomeScreenData() async {
    setState(() {
      _homeScreenCategories = null;
      _homeScreenFeaturedProducts = null;
    });
    context.read<ProductBloc>().add(FetchHomeData());
  }

  Widget _buildHomePageContentContainer() {
    return BlocConsumer<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductHomeDataLoaded) {
          if (mounted) {
            setState(() {
              _homeScreenCategories = state.categories;
              _homeScreenFeaturedProducts = state.featuredProducts;
            });
          }
        }
      },
      builder: (context, productState) {
        if (_homeScreenCategories != null && _homeScreenFeaturedProducts != null) {
          return RefreshIndicator(
            onRefresh: _refreshHomeScreenData,
            child: _buildHomePageContent(
              context,
              categories: _homeScreenCategories!,
              featuredProducts: _homeScreenFeaturedProducts!,
              isLoading: productState is ProductLoading && (_homeScreenCategories == null || _homeScreenFeaturedProducts == null),
              error: null,
            ),
          );
        }
        if (productState is ProductLoading) {
          return _buildHomePageContent(context, isLoading: true, error: null);
        } else if (productState is ProductHomeDataLoaded) {
          return RefreshIndicator(
            onRefresh: _refreshHomeScreenData,
            child: _buildHomePageContent(
              context,
              categories: productState.categories,
              featuredProducts: productState.featuredProducts,
              isLoading: false,
              error: null,
            ),
          );
        } else if (productState is ProductError) {
          return _buildHomePageContent(context, isLoading: false, error: productState.message);
        }
        print("HomeScreen Container Fallback. State: $productState");
        return RefreshIndicator(
            onRefresh: _refreshHomeScreenData,
            child: _buildHomePageContent(
              context,
              isLoading: true,
              error: null,
              showStaleDataMessage: _homeScreenCategories != null || _homeScreenFeaturedProducts != null,
            )
        );
      },
    );
  }

  Widget _buildHomePageContent(
      BuildContext context, {
        List<CategoryModel> categories = const [],
        List<ProductModel> featuredProducts = const [],
        required bool isLoading,
        String? error,
        bool showStaleDataMessage = false,
      }) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isLoading && !showStaleDataMessage && (categories.isEmpty && featuredProducts.isEmpty)) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildFullPageLoadingSliverAppBar(context, colorScheme),
          SliverList(delegate: SliverChildListDelegate([
            _buildBannerLoadingPlaceholder(context),
            const SizedBox(height: 24),
            _buildSectionHeader(context, "Categories"),
            _buildCategoriesLoadingPlaceholder(context),
            const SizedBox(height: 24),
            _buildSectionHeader(context, "Featured Products"),
            _buildProductsLoadingPlaceholder(context),
            const SizedBox(height: 24),
          ])),
        ],
      );
    }

    if (error != null && !showStaleDataMessage && (categories.isEmpty && featuredProducts.isEmpty)) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildFullPageLoadingSliverAppBar(context, colorScheme),
          SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 50),
                    const SizedBox(height: 10),
                    Text("Error: $error", textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retry"),
                      onPressed: _refreshHomeScreenData,
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      );
    }

    List<ProductModel> bannerDisplayProducts = featuredProducts.take(5).toList();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        SliverAppBar(
          pinned: true,
          floating: true,
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search products...",
                prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              ),
              onSubmitted: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Search for: $value (not implemented)")),
                );
              },
            ),
          ),
        ),
        if (showStaleDataMessage && isLoading)
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.orange.withOpacity(0.2),
              child: const Text("Refreshing data...", textAlign: TextAlign.center),
            ),
          ),
        SliverList(
          delegate: SliverChildListDelegate([
            if (isLoading && bannerDisplayProducts.isEmpty)
              _buildBannerLoadingPlaceholder(context)
            else if (bannerDisplayProducts.isNotEmpty)
              _buildBannerPageView(context, bannerDisplayProducts)
            else if (!isLoading)
                _buildStaticBannerPlaceholder(context, "Promotions Coming Soon!"),

            const SizedBox(height: 24),
            _buildSectionHeader(context, "Categories"),
            if (isLoading && categories.isEmpty)
              _buildCategoriesLoadingPlaceholder(context)
            else if (categories.isNotEmpty)
              _buildCategoriesList(context, categories)
            else if (!isLoading)
                Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20.0), child: Text("No categories available.", style: TextStyle(color: colorScheme.onSurfaceVariant)))),

            const SizedBox(height: 24),
            _buildSectionHeader(context, "Featured Products"),
            if (isLoading && featuredProducts.isEmpty)
              _buildProductsLoadingPlaceholder(context)
            else if (featuredProducts.isNotEmpty)
              _buildProductsGrid(context, featuredProducts)
            else if (!isLoading)
                Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20.0), child: Text("No featured products available.", style: TextStyle(color: colorScheme.onSurfaceVariant)))),
            const SizedBox(height: 24),
          ]),
        ),
      ],
    );
  }

  Widget _buildFullPageLoadingSliverAppBar(BuildContext context, ColorScheme colorScheme) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: TextField(
          enabled: false,
          decoration: InputDecoration(
            hintText: "Search products...",
            prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25.0),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _initializePages();

    final authState = context.watch<AuthBloc>().state;
    UserModel? currentUser;
    if (authState is AuthSuccess) {
      currentUser = authState.user;
    }
    final colorScheme = Theme.of(context).colorScheme;

    String appBarTitle = "Mini ECom";
    Widget? appBarLeading = Padding(
      padding: const EdgeInsets.all(8.0),
      child: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        child: Icon(Icons.shopping_bag_outlined, color: colorScheme.onPrimaryContainer),
      ),
    );
    List<Widget> appBarActions = [];
    bool showMainAppBar = true;

    if (_currentBottomNavIndex == 0) { // Home Tab
      appBarTitle = currentUser != null ? "Hi, ${currentUser.firstName}!" : "Mini ECom";
      if (currentUser != null && currentUser.image.isNotEmpty) {
        appBarLeading = Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundImage: NetworkImage(currentUser.image),
            onBackgroundImageError: (_, __) {},
          ),
        );
      } else if (currentUser != null) {
        appBarLeading = Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: colorScheme.secondaryContainer,
            child: Text(
              currentUser.firstName.isNotEmpty ? currentUser.firstName[0].toUpperCase() : "?",
              style: TextStyle(color: colorScheme.onSecondaryContainer, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }

      // ----------- CORRECTED appBarActions -----------
      appBarActions = [
        // Theme Toggle Button
        Consumer<ThemeProvider>( // Use Consumer to rebuild the icon when theme changes
          builder: (context, themeProvider, child) {
            return IconButton(
              icon: Icon(
                themeProvider.themeMode == ThemeMode.dark ||
                    (themeProvider.themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark)
                    ? Icons.light_mode_outlined // Show light mode icon if current is dark
                    : Icons.dark_mode_outlined,  // Show dark mode icon if current is light
              ),
              tooltip: "Toggle Theme",
              onPressed: () {
                themeProvider.toggleTheme();
              },
            );
          },
        ),
        // Notifications Button
        IconButton(
          icon: const Icon(Icons.notifications_none_outlined),
          tooltip: "Notifications",
          onPressed: () { /* TODO: Implement notifications */ },
        ),
        // Logout Button (only if user is authenticated)
        if (authState is AuthSuccess)
          IconButton(
            icon: const Icon(Icons.logout_outlined), // Correct icon for logout
            tooltip: "Logout",
            onPressed: () {
              _showLogoutDialog(context); // Call your existing logout dialog method
            },
          ),
      ];
      // ----------- END CORRECTION -----------

    } else {
      // For other tabs, check if they provide their own AppBar.
      Widget currentPageWidget = _pages[_currentBottomNavIndex];
      if (currentPageWidget is CategoriesScreen || currentPageWidget is CartScreen || currentPageWidget is ProfileScreen) {
        showMainAppBar = false;
      }
      // Set titles for tabs if HomeScreen's AppBar were to be used
      if (_currentBottomNavIndex == 1) appBarTitle = "All Categories";
      else if (_currentBottomNavIndex == 2) appBarTitle = "My Cart";
      else if (_currentBottomNavIndex == 3) appBarTitle = "Profile";
      appBarLeading = null;
      appBarActions = [];
    }

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial && state is LogoutRequested) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
          );
        }
      },
      child: Scaffold(
        appBar: showMainAppBar
            ? AppBar(
          title: Text(appBarTitle),
          leading: appBarLeading,
          actions: appBarActions,
          elevation: (_currentBottomNavIndex == 0 && showMainAppBar) ? 1 : 0,
        )
            : null,
        body: IndexedStack(
          index: _currentBottomNavIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentBottomNavIndex,
          onTap: (index) {
            setState(() {
              _currentBottomNavIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: colorScheme.onSurfaceVariant,
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 8.0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.category_outlined), activeIcon: Icon(Icons.category), label: "Categories"),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), activeIcon: Icon(Icons.shopping_cart), label: "Cart"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'smartphones': return Icons.phone_android;
      case 'laptops': return Icons.laptop_mac;
      case 'fragrances': return Icons.style_outlined;
      case 'skincare': return Icons.spa_outlined;
      case 'groceries': return Icons.local_grocery_store;
      case 'home-decoration': return Icons.home_work_outlined;
      case 'furniture': return Icons.chair_outlined;
      case 'tops': case 'womens-dresses': case 'womens-shoes':
      case 'mens-shirts': case 'mens-shoes': case 'mens-watches':
      case 'womens-watches': case 'womens-bags': case 'womens-jewellery':
      return Icons.checkroom;
      case 'sunglasses': return Icons.wb_sunny_outlined;
      case 'automotive': return Icons.directions_car_outlined;
      case 'motorcycle': return Icons.motorcycle_outlined;
      case 'lighting': return Icons.lightbulb_outline;
      default: return Icons.category;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Logout'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<AuthBloc>().add(LogoutRequested());
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
          TextButton(
            onPressed: () {
              if (title.toLowerCase() == "categories") {
                if (_currentBottomNavIndex != 1) {
                  setState(() { _currentBottomNavIndex = 1; });
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("View All $title (not implemented)")));
              }
            },
            child: Text("View All", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerPageView( BuildContext context, List<ProductModel> productsForBanner) {
    if (productsForBanner.isEmpty) return _buildStaticBannerPlaceholder(context, "No promotions.");
    return Column(
      children: [
        SizedBox(
          height: 190.0,
          child: PageView.builder(
            controller: _bannerPageController,
            itemCount: productsForBanner.length,
            onPageChanged: (index) => setState(() => _currentPageViewBannerIndex = index),
            itemBuilder: (context, index) {
              final product = productsForBanner[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreenSimple(product: product),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12.0),
                    image: DecorationImage(image: NetworkImage(product.thumbnail), fit: BoxFit.cover, onError: (o,s){}),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3))],
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      color: Colors.black.withOpacity(0.4),
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                      child: Text(product.title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (productsForBanner.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(productsForBanner.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
              height: 8.0, width: _currentPageViewBannerIndex == i ? 24.0 : 8.0,
              decoration: BoxDecoration(color: _currentPageViewBannerIndex == i ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.4), borderRadius: BorderRadius.circular(12)),
            )),
          ),
      ],
    );
  }

  Widget _buildStaticBannerPlaceholder(BuildContext context, String message) {
    return Container(
      height: 190, margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(12.0), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3))]),
      child: Center(child: Text(message, style: TextStyle(fontSize: 18, color: Colors.black.withOpacity(0.6), fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
    );
  }

  Widget _buildBannerLoadingPlaceholder(BuildContext context) {
    return Container(
      height: 190.0, width: double.infinity, margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(12.0)),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildCategoriesList( BuildContext context, List<CategoryModel> categories) {
    if (categories.isEmpty && mounted) return const SizedBox.shrink();
    if (categories.isEmpty) return const SizedBox(height:100, child:Center(child: Text("No categories.")));

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductsByCategoryScreen(category: category))),
              borderRadius: BorderRadius.circular(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
                    child: Icon(_getIconForCategory(category.name), size: 28, color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(width: 70, child: Text(category.name.replaceAll('-', ' ').split(' ').map((e) => e[0].toUpperCase()+e.substring(1)).join(' '), style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesLoadingPlaceholder(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12.0), itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircleAvatar(radius: 30, backgroundColor: Colors.grey.shade300), const SizedBox(height: 8), Container(width: 60, height: 10, color: Colors.grey.shade300)]),
        ),
      ),
    );
  }

  Widget _buildProductsGrid( BuildContext context, List<ProductModel> products) {
    if (products.isEmpty && mounted) return const SizedBox.shrink();
    if (products.isEmpty) return const SizedBox(height: 200, child: Center(child: Text("No products.")));

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    const double gridCrossAxisSpacing = 12, gridMainAxisSpacing = 12, desiredItemHeight = 310; // Adjusted for wishlist icon
    const int gridCrossAxisCount = 2;
    final double itemWidth = (MediaQuery.of(context).size.width - (16.0 * 2) - (gridCrossAxisSpacing * (gridCrossAxisCount - 1))) / gridCrossAxisCount;
    final double gridChildAspectRatio = itemWidth / desiredItemHeight;

    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: gridCrossAxisCount, crossAxisSpacing: gridCrossAxisSpacing, mainAxisSpacing: gridMainAxisSpacing, childAspectRatio: gridChildAspectRatio),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          elevation: 2.0, clipBehavior: Clip.antiAlias, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
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
                            flex: 3,
                            child: Container(width: double.infinity, decoration: BoxDecoration(image: DecorationImage(image: NetworkImage(product.thumbnail), fit: BoxFit.cover, onError: (o,s){} ))),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(product.brand, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.8)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text("\$${product.discountedPrice.toStringAsFixed(2)}", style: textTheme.titleMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                                    if (product.oldPrice != null) ...[ const SizedBox(width: 6), Text("\$${product.oldPrice!.toStringAsFixed(2)}", style: textTheme.labelSmall?.copyWith(decoration: TextDecoration.lineThrough, color: colorScheme.onSurfaceVariant.withOpacity(0.7)))],
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
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: textTheme.labelLarge,
                  ),
                  onPressed: () {
                    context.read<CartBloc>().add(AddToCart(product));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${product.title} added to cart"), backgroundColor: Colors.green, duration: const Duration(seconds: 1),));
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductsLoadingPlaceholder(BuildContext context) {
    const int gridCrossAxisCount = 2; const double desiredItemHeight = 310; // Adjusted
    final double itemWidth = (MediaQuery.of(context).size.width - (16.0 * 2) - (12 * (gridCrossAxisCount - 1))) / gridCrossAxisCount;
    final double gridChildAspectRatio = itemWidth / desiredItemHeight;
    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: gridCrossAxisCount, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: gridChildAspectRatio),
      itemCount: 4,
      itemBuilder: (context, index) => Card(
        elevation: 2.0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 3, child: Container(color: Colors.grey.shade300)),
          Padding(padding: const EdgeInsets.all(8.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: double.infinity, height: 14, color: Colors.grey.shade300), const SizedBox(height: 4),
            Container(width: MediaQuery.of(context).size.width * 0.2, height: 12, color: Colors.grey.shade300), const SizedBox(height: 6),
            Container(width: MediaQuery.of(context).size.width * 0.15, height: 16, color: Colors.grey.shade300), const SizedBox(height: 10),
            Container(width: double.infinity, height: 30, color: Colors.grey.shade300),
          ]))
        ]),
      ),
    );
  }
}