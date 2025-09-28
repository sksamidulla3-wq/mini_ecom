part of 'product_bloc.dart';

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductHomeDataLoaded extends ProductState {
  final List<CategoryModel> categories;
  final List<ProductModel> featuredProducts;

  const ProductHomeDataLoaded({required this.categories, required this.featuredProducts});@override
  List<Object> get props => [categories, featuredProducts];
}

class ProductError extends ProductState {
  final String message;

  const ProductError({required this.message});

  @override
  List<Object> get props => [message];
}

// ... (existing states) ...

class ProductsByCategoryLoaded extends ProductState {
  final List<ProductModel> products;
  final String categoryName; // To confirm which category's products are loaded

  const ProductsByCategoryLoaded({required this.products, required this.categoryName});

  @override
  List<Object> get props => [products, categoryName];
}