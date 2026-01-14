part of 'pagos_bloc.dart';

abstract class PagoEvent {}

class CargarPagosEvent extends PagoEvent {}

class CargarPagosPorSocioEvent extends PagoEvent {
  final int socioId;
  CargarPagosPorSocioEvent(this.socioId);
}

class AgregarPagoEvent extends PagoEvent {
  final Pago pago;
  AgregarPagoEvent(this.pago);
}

class EliminarPagoEvent extends PagoEvent {
  final int pagoId;
  EliminarPagoEvent(this.pagoId);
}
