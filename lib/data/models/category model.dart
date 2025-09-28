// lib/data/models/category_model.dart
import 'package:equatable/equatable.dart';

class CategoryModel extends Equatable {
  final String name;

  const CategoryModel({required this.name});

  @override
  List<Object?> get props => [name];
}