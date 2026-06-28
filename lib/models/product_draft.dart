import 'package:flutter/material.dart';

class ProductDraft {
  const ProductDraft({
    required this.name,
    required this.category,
    required this.price,
    required this.color,
    required this.icon,
  });

  final String name;
  final String category;
  final int price;
  final Color color;
  final IconData icon;
}