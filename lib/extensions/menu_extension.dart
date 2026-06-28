import 'package:flutter/material.dart';

import '../models/menu_model.dart';

extension MenuPresentation on MenuModel {
  Color get color {
    switch (category) {
      case 'Meals':
        return const Color(0xFFFFD7C2);

      case 'Drinks':
        return const Color(0xFFD9F1E2);

      case 'Snacks':
        return const Color(0xFFFFEDB5);

      case 'Dessert':
        return const Color(0xFFE7D4C5);

      default:
        return const Color(0xFFFFD7C2);
    }
  }

  IconData get icon {
    switch (category) {
      case 'Meals':
        return Icons.rice_bowl;

      case 'Drinks':
        return Icons.local_cafe;

      case 'Snacks':
        return Icons.fastfood;

      case 'Dessert':
        return Icons.bakery_dining;

      default:
        return Icons.restaurant_menu;
    }
  }
}