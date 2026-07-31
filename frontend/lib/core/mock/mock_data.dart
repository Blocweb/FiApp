import 'package:fiapp/features/clients/data/models/client_model.dart';
import 'package:fiapp/features/history/data/models/transaction_model.dart';
import 'package:fiapp/features/history/domain/entities/transaction.dart';
import 'package:fiapp/features/fiados/data/models/fiado_item_model.dart';

/// Datos de ejemplo (mock) usados mientras la API REST en ASP.NET Core no
/// está disponible. Mantienen exactamente la misma estructura que tendrá
/// la respuesta JSON real, para que migrar a datasources remotos sea
/// solo cuestión de cambiar la fuente de datos, no el modelo.
class MockData {
  MockData._();

  static final List<ClientModel> clients = [
    ClientModel.fromJson(const {
      'id': '1',
      'name': 'María García',
      'phone': '311 456 7890',
      'address': 'Cra 5 #23-41, Barrio El Centro',
      'notes': 'Cliente frecuente, siempre paga los viernes',
      'colorHex': '#8B5CF6',
      'balance': 47500.0,
      'lastMovement': 'Hace 2 días',
    }),
    ClientModel.fromJson(const {
      'id': '2',
      'name': 'Carlos Rodríguez',
      'phone': '300 123 4567',
      'address': 'Cl 8 #12-05, Barrio La Paz',
      'notes': '',
      'colorHex': '#F59E0B',
      'balance': 0.0,
      'lastMovement': 'Hace 1 semana',
    }),
    ClientModel.fromJson(const {
      'id': '3',
      'name': 'Ana Martínez',
      'phone': '315 789 0123',
      'address': 'Tv 10 #34-12, Barrio Nuevo',
      'notes': 'Compra todos los días',
      'colorHex': '#EF4444',
      'balance': 125000.0,
      'lastMovement': 'Hoy',
    }),
    ClientModel.fromJson(const {
      'id': '4',
      'name': 'Luis Herrera',
      'phone': '320 456 1234',
      'address': 'Cl 15 #8-90',
      'notes': '',
      'colorHex': '#06B6D4',
      'balance': 18000.0,
      'lastMovement': 'Ayer',
    }),
    ClientModel.fromJson(const {
      'id': '5',
      'name': 'Sandra López',
      'phone': '316 234 5678',
      'address': 'Cra 12 #45-67',
      'notes': '',
      'colorHex': '#EC4899',
      'balance': 0.0,
      'lastMovement': 'Hace 3 días',
    }),
    ClientModel.fromJson(const {
      'id': '6',
      'name': 'Jorge Moreno',
      'phone': '301 567 8901',
      'address': 'Diagonal 25 #10-20',
      'notes': 'Trabajador de la construcción',
      'colorHex': '#10B981',
      'balance': 65000.0,
      'lastMovement': 'Hace 4 días',
    }),
  ];

  static final List<TransactionModel> transactions = [
    const TransactionModel(
      id: 't1',
      clientId: '3',
      type: TransactionType.fiado,
      date: 'Hoy',
      time: '09:30',
      amount: 35000,
      items: [
        FiadoItemModel(id: 'i1', name: 'Arroz 3kg', qty: 2, price: 8500),
        FiadoItemModel(id: 'i2', name: 'Aceite 1L', qty: 1, price: 12000),
        FiadoItemModel(id: 'i3', name: 'Panela', qty: 1, price: 6000),
      ],
      balanceAfter: 125000,
    ),
    const TransactionModel(
      id: 't2',
      clientId: '1',
      type: TransactionType.abono,
      date: 'Ayer',
      time: '16:45',
      amount: 20000,
      paymentMethod: 'Efectivo',
      balanceAfter: 47500,
    ),
    const TransactionModel(
      id: 't3',
      clientId: '4',
      type: TransactionType.fiado,
      date: 'Ayer',
      time: '11:20',
      amount: 18000,
      items: [
        FiadoItemModel(id: 'i4', name: 'Pan tajado', qty: 2, price: 4500),
        FiadoItemModel(id: 'i5', name: 'Leche 1L', qty: 3, price: 3000),
      ],
      balanceAfter: 18000,
    ),
    const TransactionModel(
      id: 't4',
      clientId: '6',
      type: TransactionType.fiado,
      date: 'Hace 2 días',
      time: '08:15',
      amount: 45000,
      items: [
        FiadoItemModel(id: 'i6', name: 'Cemento x5', qty: 1, price: 35000),
        FiadoItemModel(id: 'i7', name: 'Arena', qty: 2, price: 5000),
      ],
      balanceAfter: 65000,
    ),
    const TransactionModel(
      id: 't5',
      clientId: '2',
      type: TransactionType.abono,
      date: 'Hace 3 días',
      time: '17:00',
      amount: 50000,
      paymentMethod: 'Transferencia',
      balanceAfter: 0,
    ),
    const TransactionModel(
      id: 't6',
      clientId: '1',
      type: TransactionType.fiado,
      date: 'Hace 4 días',
      time: '10:30',
      amount: 32000,
      items: [
        FiadoItemModel(id: 'i8', name: 'Jabón Ariel 500g', qty: 2, price: 8000),
        FiadoItemModel(id: 'i9', name: 'Detergente', qty: 1, price: 9500),
        FiadoItemModel(id: 'i10', name: 'Suavizante', qty: 1, price: 6500),
      ],
      balanceAfter: 67500,
    ),
    const TransactionModel(
      id: 't7',
      clientId: '3',
      type: TransactionType.abono,
      date: 'Hace 5 días',
      time: '13:00',
      amount: 40000,
      paymentMethod: 'Efectivo',
      balanceAfter: 90000,
    ),
    const TransactionModel(
      id: 't8',
      clientId: '6',
      type: TransactionType.fiado,
      date: 'Hace 6 días',
      time: '07:45',
      amount: 20000,
      items: [
        FiadoItemModel(id: 'i11', name: 'Ladrillo x10', qty: 2, price: 10000),
      ],
      balanceAfter: 20000,
    ),
  ];
}
