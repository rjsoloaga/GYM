import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym/repositories/database_helper.dart';
import 'package:gym/models/socio.dart';


part 'socios_event.dart';
part 'socios_state.dart';


class SociosBloc extends Bloc<SocioEvent, SociosState> {
  final DatabaseHelper databaseHelper;

  SociosBloc(this.databaseHelper) : super(SociosInitialState()) {
    // Atentos a que evento se llama
    on<CargarSociosEvent>(_onCargarSocios);
    on<AgregarSocioEvent>(_onAgregarSocio);
    on<ActualizarSocioEvent>(_onActualizarSocio);
    on<EliminarSocioEvent>(_onEliminarSocio);
  }

  // Funcion para carga de socios
  Future<void> _onCargarSocios(
    CargarSociosEvent event,
    Emitter<SociosState> emit,
  ) async {
    emit(SociosCargandoState()); // Emitir estado de carga

    try {
      final socios = await databaseHelper.getSocios();
      emit(SociosCargadosState(socios)); //Emitir esado con datos
    } catch (e) {
      emit(SociosErrorState('Error al cargar socios: $e'));
    }
  }

  // Funcion para agregar un socio
  Future<void> _onAgregarSocio(
    AgregarSocioEvent event,
    Emitter<SociosState> emit,
  ) async {
    try {
      await databaseHelper.insertarSocio(event.socio);
      // Recargar la lista despues de agregar
      add(CargarSociosEvent());
    } catch (e) {
      emit(SociosErrorState('Error al agregar socio: $e'));
    }
  }

  // Funcion para actualizar un socio
  Future<void> _onActualizarSocio(
    ActualizarSocioEvent event,
    Emitter<SociosState> emit,
  ) async {
    print('Bloc: Actualizando socio ID: ${event.socio.id}');
    try {
      final resultado = await databaseHelper.updateSocio(event.socio);
      // Recargar la lista despues de actualizar
      add(CargarSociosEvent());
    } catch (e) {
      print('Bloc: Error en update: $e');
      emit(SociosErrorState('Error al actualizar socio: $e'));
    }
  }

  // Funcion para eliminar un socio
  Future<void> _onEliminarSocio(
    EliminarSocioEvent event,
    Emitter<SociosState> emit,
  ) async {
    try {
      await databaseHelper.deleteSocio(event.id);
      // Recargar la lista despues de eliminar un socio
      add(CargarSociosEvent());
    } catch (e) {
      emit(SociosErrorState('Error al eliminar socio: $e'));
    }
  }
  

  
}