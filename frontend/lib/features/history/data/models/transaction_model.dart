import 'package:fiapp/features/fiados/data/models/fiado_item_model.dart';
import 'package:fiapp/features/history/domain/entities/transaction.dart';

/// Modelo de datos de [Transaction].
///
/// JSON esperado del futuro backend ASP.NET Core:
/// ```json
/// {
///   "id": "t1",
///   "clientId": "3",
///   "type": "fiado",
///   "date": "Hoy",
///   "time": "09:30",
///   "amount": 35000.0,
///   "items": [ { "id": "i1", "name": "Arroz 3kg", "qty": 2, "price": 8500.0 } ],
///   "paymentMethod": null,
///   "note": null,
///   "balanceAfter": 125000.0
/// }
/// ```
class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.clientId,
    required super.type,
    required super.date,
    required super.time,
    required super.amount,
    super.items,
    super.paymentMethod,
    super.note,
    required super.balanceAfter,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      type: (json['type'] as String) == 'fiado'
          ? TransactionType.fiado
          : TransactionType.abono,
      date: json['date'] as String,
      time: json['time'] as String,
      amount: (json['amount'] as num).toDouble(),
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => FiadoItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      paymentMethod: json['paymentMethod'] as String?,
      note: json['note'] as String?,
      balanceAfter: (json['balanceAfter'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'type': type == TransactionType.fiado ? 'fiado' : 'abono',
      'date': date,
      'time': time,
      'amount': amount,
      'items': items
          ?.map((e) => FiadoItemModel.fromEntity(e).toJson())
          .toList(),
      'paymentMethod': paymentMethod,
      'note': note,
      'balanceAfter': balanceAfter,
    };
  }

  factory TransactionModel.fromEntity(Transaction tx) {
    return TransactionModel(
      id: tx.id,
      clientId: tx.clientId,
      type: tx.type,
      date: tx.date,
      time: tx.time,
      amount: tx.amount,
      items: tx.items,
      paymentMethod: tx.paymentMethod,
      note: tx.note,
      balanceAfter: tx.balanceAfter,
    );
  }
}
