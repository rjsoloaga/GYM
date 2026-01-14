import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym/repositories/database_helper.dart';
import 'package:gym/models/pago.dart';

part 'pagos_event.dart';
part 'pagos_state.dart';

class PagosBloc extends Bloc<PagoEvent, PagosState> {
  final DatabaseHelper databaseHelper;

  PagosBloc(this.databaseHelper) : super(PagosInitialState()) {
    on<CargarPagosEvent>(_onCargarPagos);
    on<CargarPagosPorSocioEvent>(_onCargarPagosPorSocio);
    on<AgregarPagoEvent>(_onAgregarPago);
    on<EliminarPagoEvent>(_onEliminarPago);
  }

  Future<void> _onCargarPagos(
    CargarPagosEvent event,
    Emitter<PagosState> emit,
  ) async {
    emit(PagosCargandoState());
    try {
      final pagos = await databaseHelper.getTodosLosPagos();
      emit(PagosCargadosState(pagos: pagos));
    } catch (e) {
      emit(PagosErrorState('Error al cargar pagos: $e'));
    }
  }

  Future<void> _onCargarPagosPorSocio(
    CargarPagosPorSocioEvent event,
    Emitter<PagosState> emit,
  ) async {
    emit(PagosCargandoState());
    try {
      final pagos = await databaseHelper.getPagosPorSocio(event.socioId);
      emit(PagosCargadosState(pagos: pagos));
    } catch (e) {
      emit(PagosErrorState('Error al cargar pagos: $e'));
    }
  }

  Future<void> _onAgregarPago(
    AgregarPagoEvent event,
    Emitter<PagosState> emit,
  ) async {
    emit(PagosCargandoState());
    try {
      await databaseHelper.insertarPago(event.pago);
      final pagos = await databaseHelper.getPagosPorSocio(event.pago.socioId);
      emit(PagosCargadosState(pagos: pagos));
    } catch (e) {
      emit(PagosErrorState('Error al agregar pago: $e'));
    }
  }

  Future<void> _onEliminarPago(
    EliminarPagoEvent event,
    Emitter<PagosState> emit,
  ) async {
    emit(PagosCargandoState());
    try {
      await databaseHelper.eliminarPago(event.pagoId);
      final pagos = await databaseHelper.getTodosLosPagos();
      emit(PagosCargadosState(pagos: pagos));
    } catch (e) {
      emit(PagosErrorState('Error al eliminar pago: $e'));
    }
  }
}
