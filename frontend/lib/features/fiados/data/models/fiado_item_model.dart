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
    return FiadoItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      qty: (json['qty'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
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
