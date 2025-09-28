part of 'product_bloc.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => []; // Use List<Object?> for props if some can be null
}

class FetchHomeData extends ProductEvent {
  final bool? forceRefresh; // <<--- ADD THIS FIELD

  const FetchHomeData({this.forceRefresh}); // <<--- UPDATE CONSTRUCTOR

  @override
  List<Object?> get props => [forceRefresh]; // <<--- ADD TO PROPS
}

class FetchProductsByCategory extends ProductEvent {
  final String categorySlug;
  final bool? forceRefresh; // <<--- ADD THIS FIELD

  const FetchProductsByCategory(this.categorySlug, {this.forceRefresh}); // <<--- UPDATE CONSTRUCTOR

  @override
  List<Object?> get props => [categorySlug, forceRefresh]; // <<--- ADD TO PROPS
}
