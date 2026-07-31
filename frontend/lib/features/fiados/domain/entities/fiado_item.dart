import 'package:equatable/equatable.dart';

/// Un producto individual dentro de un fiado (ej: "Arroz 3kg", cantidad 2,
/// precio unitario 8500).
class FiadoItem extends Equatable {
  final String id;
  final String name;
  final int qty;
  final double price;

  const FiadoItem({
    required this.id,
    required this.name,
    required this.qty,
    required this.price,
  });

  double get subtotal => qty * price;

  FiadoItem copyWith({
    String? id,
    String? name,
    int? qty,
    double? price,
  }) {
    return FiadoItem(
      id: id ?? this.id,
      name: name ?? this.name,
      qty: qty ?? this.qty,
      price: price ?? this.price,
    );
  }

  @override
  List<Object?> get props => [id, name, qty, price];
}
