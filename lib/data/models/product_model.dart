import 'dart:convert';

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
      'apiId': id, // Assuming your ProductModel 'id' is the API ID
      'title': title,
      'description': description,
      'price': price,
      'discountPercentage': discountPercentage,
      'rating': rating,
      'stock': stock,
      'brand': brand,
      'category': category,
      'imageUrl': thumbnail, // <<--- CHANGE 'thumbnail' KEY TO 'imageUrl'
      // 'images': jsonEncode(images), // If you store multiple images
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  factory ProductModel.fromPersistenceMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['apiId'] as int,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      price: (map['price'] as num? ?? 0.0).toDouble(),
      discountPercentage: (map['discountPercentage'] as num? ?? 0.0).toDouble(),
      rating: (map['rating'] as num? ?? 0.0).toDouble(),
      stock: map['stock'] as int? ?? 0,
      brand: map['brand'] as String? ?? '',
      category: map['category'] as String? ?? '',
      thumbnail: map['imageUrl'] as String? ?? '', // <<--- READ FROM 'imageUrl'
      images: map['images'] != null ? List<String>.from(jsonDecode(map['images'])) : [],
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
