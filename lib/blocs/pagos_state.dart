part of 'pagos_bloc.dart';

abstract class PagosState {}

class PagosInitialState extends PagosState {}

class PagosCargandoState extends PagosState {}

class PagosCargadosState extends PagosState {
  final List<Pago> pagos;
  PagosCargadosState({required this.pagos});
}

class PagosErrorState extends PagosState {
  final String error;
  PagosErrorState(this.error);
}
