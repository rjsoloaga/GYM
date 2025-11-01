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
    on<BuscarSociosEvent>(_onBuscarSocios);
  }

  // Funcion para carga de socios
  Future<void> _onCargarSocios(
    CargarSociosEvent event,
    Emitter<SociosState> emit,
  ) async {
    emit(SociosCargandoState()); // Emitir estado de carga

    try {
      final socios = await databaseHelper.getSocios();
      emit(SociosCargadosState(
        todosLosSocios: socios,
        sociosFiltrados: socios,
        textoBusqueda: '',
      )); //Emitir esado con datos
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

  // Función helper para filtrar
  List<Socio> _filtrarSocios(List<Socio> socios, String texto) {
    if (texto.isEmpty) {
      return socios; // Si no hay texto, mostrar todos
    }
    
    final textoLower = texto.toLowerCase();
    
    return socios.where((socio) {
      return socio.nombreCompleto.toLowerCase().contains(textoLower) ||
            socio.dni.contains(texto) || // DNI exacto (sin lower)
            socio.telefono.contains(texto); // Teléfono exacto
    }).toList();
  }
  
  Future<void> _onBuscarSocios(
    BuscarSociosEvent event,
    Emitter<SociosState> emit,
  ) async {
    // Solo podemos buscar si ya tenemos socios cargados
    if (state is SociosCargadosState) {
      final estadoActual = state as SociosCargadosState;
      
      // Aplicar el filtro usando nuestra función helper
      final sociosFiltrados = _filtrarSocios(
        estadoActual.todosLosSocios,
        event.texto
      );
      
      // Emitir nuevo estado con los resultados filtrados
      emit(SociosCargadosState(
        todosLosSocios: estadoActual.todosLosSocios,
        sociosFiltrados: sociosFiltrados,
        textoBusqueda: event.texto,
      ));
    }
  }

  
}