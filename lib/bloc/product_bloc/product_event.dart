part of 'product_bloc.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object> get props => [];
}

class FetchHomeData extends ProductEvent {} // Fetches both categories and featured products
// ... (existing events) ...

class FetchProductsByCategory extends ProductEvent {
  final String categorySlug; // Or categoryName, depending on your API
  const FetchProductsByCategory(this.categorySlug);

  @override
  List<Object> get props => [categorySlug];
}


// Later you might add:
// class FetchProductsByCategory extends ProductEvent {
//   final String categoryName;
//   const FetchProductsByCategory(this.categoryName);
//   @override List<Object> get props => [categoryName];
// }
// class SearchProducts extends ProductEvent {
//   final String query;
//   const SearchProducts(this.query);
//   @override List<Object> get props => [query];
// }