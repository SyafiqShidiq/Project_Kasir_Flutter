import 'package:flutter/material.dart';

class MenuDraft {
  const MenuDraft({
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