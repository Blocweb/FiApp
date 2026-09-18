import 'package:fiapp/features/fiados/domain/entities/fiado_item.dart';

/// Modelo de datos de [FiadoItem], mapea el JSON esperado del futuro
/// backend ASP.NET Core:
/// ```json
/// { "id": "i1", "name": "Arroz 3kg", "qty": 2, "price": 8500.0 }
/// ```
class FiadoItemModel extends FiadoItem {
  const FiadoItemModel({
    required super.id,
    required super.name,
    required super.qty,
    required super.price,
  });

  factory FiadoItemModel.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'];
    final price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '') ?? 0.0;

    final rawQty = json['qty'];
    final qty = rawQty is num
        ? rawQty.toInt()
        : int.tryParse(rawQty?.toString() ?? '') ?? 1;

    return FiadoItemModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      qty: qty,
      price: price,
    );
  }

  factory FiadoItemModel.fromApiJson(Map<String, dynamic> json) {
    final rawPrice = json['precio_unitario'];
    final price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '') ?? 0.0;

    final rawQty = json['cantidad'];
    final qty = rawQty is num
        ? rawQty.toInt()
        : int.tryParse(rawQty?.toString() ?? '') ?? 1;

    return FiadoItemModel(
      id: json['producto_id'] as String? ?? json['id'] as String? ?? '',
      name: json['nombre_producto'] as String? ?? '',
      qty: qty,
      price: price,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'qty': qty,
      'price': price,
    };
  }

  factory FiadoItemModel.fromEntity(FiadoItem item) {
    return FiadoItemModel(
      id: item.id,
      name: item.name,
      qty: item.qty,
      price: item.price,
    );
  }
}
