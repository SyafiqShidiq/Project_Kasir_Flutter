import 'menu_model.dart';

class CartLine {
  const CartLine({
    required this.product,
    required this.quantity,
  });

  final MenuModel product;
  final int quantity;

  int get subtotal =>
      product.price.toInt() * quantity;

  CartLine copyWith({
    int? quantity,
  }) {
    return CartLine(
      product: product,
      quantity:
          quantity ?? this.quantity,
    );
  }
}

class CartState {
  const CartState({
    required this.lines,
  });

  final List<CartLine> lines;

  int get itemCount => lines.fold(
        0,
        (total, line) =>
            total + line.quantity,
      );

  int get subtotal => lines.fold(
        0,
        (total, line) =>
            total + line.subtotal,
      );

  int get tax =>
      (subtotal * 0.1).round();

  int get service =>
      itemCount == 0 ? 0 : 4000;

  int get total =>
      subtotal + tax + service;

  CartState copyWith({
    List<CartLine>? lines,
  }) {
    return CartState(
      lines: lines ?? this.lines,
    );
  }
}