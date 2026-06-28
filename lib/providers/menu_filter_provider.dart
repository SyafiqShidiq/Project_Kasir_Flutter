import 'package:flutter_riverpod/flutter_riverpod.dart';

class MenuFilterController extends Notifier<MenuFilter> {
  @override
  MenuFilter build() => const MenuFilter();

  void search(String query) {
    state = state.copyWith(query: query);
  }

  void selectCategory(String category) {
    state = state.copyWith(category: category);
  }
}
class MenuFilter {
  const MenuFilter({this.query = '', this.category = allCategory});

  static const allCategory = 'All';

  final String query;
  final String category;

  MenuFilter copyWith({String? query, String? category}) {
    return MenuFilter(
      query: query ?? this.query,
      category: category ?? this.category,
    );
  }
}
final menuFilterProvider = NotifierProvider<MenuFilterController, MenuFilter>(
  MenuFilterController.new,
);