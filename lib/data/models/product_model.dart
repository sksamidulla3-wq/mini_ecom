import 'package:equatable/equatable.dart';class ProductModel extends Equatable {
  final int id;
  final String title;
  final String description; // Keep for detail view if needed, or omit from persistence map
  final num price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final String brand;
  final String category;
  final String thumbnail;
  final List<String> images; // Keep for detail view, or just store thumbnail for persistence

  const ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.stock,
    required this.brand,
    required this.category,
    required this.thumbnail,
    required this.images,
  });

  double get discountedPrice {
    return price * (1 - (discountPercentage / 100.0));
  }

  double? get oldPrice {
    if (discountPercentage > 0) {
      return price.toDouble();
    }
    return null;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      price: json['price'] as num,
      discountPercentage: (json['discountPercentage'] as num? ?? 0.0).toDouble(), // Handle potential null
      rating: (json['rating'] as num? ?? 0.0).toDouble(), // Handle potential null
      stock: json['stock'] as int? ?? 0, // Handle potential null
      brand: json['brand'] as String? ?? '',
      category: json['category'] as String? ?? '', // Handle potential null category from bad data
      thumbnail: json['thumbnail'] as String? ?? '', // Handle potential null
      images: List<String>.from(json['images'] as List? ?? []),
    );
  }

  // --- ADD METHODS FOR PERSISTENCE ---
  Map<String, dynamic> toPersistenceMap() {
    return {
      'id': id,
      'title': title,
      'price': price, // Store original price
      'discountPercentage': discountPercentage, // Store discount
      'thumbnail': thumbnail,
      'brand': brand, // Optional: for display on wishlist/cart item
      'category': category, // Optional
      // No need to store 'description' or full 'images' list for cart/wishlist usually
      // No need to store 'stock' or 'rating' if they can change and should be fetched live
      // or if they are just for display on product detail page.
    };
  }

  factory ProductModel.fromPersistenceMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int,
      title: map['title'] as String,
      price: map['price'] as num,
      discountPercentage: (map['discountPercentage'] as num? ?? 0.0).toDouble(),
      thumbnail: map['thumbnail'] as String? ?? '',
      brand: map['brand'] as String? ?? '',
      category: map['category'] as String? ?? '',
      // Fill other fields with defaults or mark as not fully loaded if needed
      description: '', // Not stored, so default or fetch later
      images: map['thumbnail'] != null && (map['thumbnail'] as String).isNotEmpty ? [map['thumbnail'] as String] : [], // Default to thumbnail in images if only thumbnail stored
      rating: 0.0,    // Not stored
      stock: 0,       // Not stored
    );
  }
  // --- END METHODS FOR PERSISTENCE ---


  @override
  List<Object?> get props => [
    id,
    title,
    description,
    price,
    discountPercentage,
    rating,
    stock,
    brand,
    category,
    thumbnail,
    images
  ];
}
