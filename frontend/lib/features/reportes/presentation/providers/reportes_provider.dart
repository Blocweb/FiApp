import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiapp/features/reportes/data/repositories/reporte_repository_remote_impl.dart';
import 'package:fiapp/features/reportes/domain/entities/reporte.dart';

class ReportesState {
  final ResumenNegocio? resumen;
  final List<EvolucionMensual> evolucion;
  final bool isLoading;
  final String? error;

  const ReportesState({
    this.resumen,
    this.evolucion = const [],
    this.isLoading = false,
    this.error,
  });

  ReportesState copyWith({
    ResumenNegocio? resumen,
    List<EvolucionMensual>? evolucion,
    bool? isLoading,
    String? error,
  }) {
    return ReportesState(
      resumen: resumen ?? this.resumen,
      evolucion: evolucion ?? this.evolucion,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ReportesNotifier extends StateNotifier<ReportesState> {
  ReportesNotifier() : super(const ReportesState()) {
    load();
  }

  final _repo = ReporteRepositoryRemoteImpl();

  Future<void> load() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await Future.wait([
        _repo.getResumen(),
        _repo.getEvolucion(),
      ]);
      if (!mounted) return;

      state = state.copyWith(
        resumen: results[0] as ResumenNegocio,
        evolucion: results[1] as List<EvolucionMensual>,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'No se pudieron cargar los reportes',
      );
    }
  }
}

final reportesProvider =
    StateNotifierProvider.autoDispose<ReportesNotifier, ReportesState>((ref) {
  return ReportesNotifier();
});
