
//Definimos la clase, nuestro modelo para crear los objetos 'Socio'
class Socio {
    final int? id;
    final String nombreCompleto;
    final String dni;
    final String telefono;
    final DateTime fechaInicio;
    final DateTime fechaVencimiento;
    final double precioMensual;
    final String tipoPlan;

    //Contructor
    Socio({
        this.id,
        required this.nombreCompleto,
        required this.dni,
        required this.telefono,
        required this.fechaInicio,
        required this.fechaVencimiento,
        required this.precioMensual,
        required this.tipoPlan,
    });

    //Metodo getter para obtener el estado de la cuota
    //Devuelve 'Verde' si la cuota esta vencida, 'Amarillo' si falta menos de 15 dias y 'Rojo' si esta vencida
    String get estadoCuota{
        final hoy = DateTime.now();
        final diferencia = fechaVencimiento.difference(hoy).inDays;

        if (diferencia >= 0) { 
            return 'Verde';
        } else if (diferencia.abs() <= 15) {
            return 'Ambar';
        } else {
            return 'Rojo';
        }
    }

    //Metodo para crear una copia del objeto 'Socio' con los valores modificados
    //Sirve para editar los valores de un 'Socio'
    Socio copyWith({
        int? id,
        String? nombreCompleto,
        String? dni,
        String? telefono,
        DateTime? fechaInicio,
        DateTime? fechaVencimiento,
        double? precioMensual,
        String? tipoPlan,
    }) {
        return Socio(
            id: id ?? this.id,
            nombreCompleto: nombreCompleto ?? this.nombreCompleto,
            dni: dni ?? this.dni,
            telefono: telefono ?? this.telefono,
            fechaInicio: fechaInicio ?? this.fechaInicio,
            fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
            precioMensual: precioMensual ?? this.precioMensual,
            tipoPlan: tipoPlan ?? this.tipoPlan,
        );
    }

    //Metodo para convertir un socio a un Map(Diccionario)
    Map<String, dynamic> toMap() {
    final map = {
      'id': id,
      'nombreCompleto': nombreCompleto,
      'dni': dni,
      'telefono': telefono,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaVencimiento': fechaVencimiento.toIso8601String(),
      'precioMensual': precioMensual,
      'tipoPlan': tipoPlan,
    };
    // Si el id es nulo, lo removemos del mapa para que la base de datos lo autogenere.
    if (id == null) {
      map.remove('id');
    }
    return map;
  }

    //Metodo para crear un Socio a partir de un Map (de la base de datos)
    factory Socio.fromMap(Map<String, dynamic> map) {
        return Socio(
            id: map['id'],
            nombreCompleto: map['nombreCompleto'],
            dni: map['dni'],
            telefono: map['telefono'],
            fechaInicio: DateTime.parse(map['fechaInicio']),//Convertimos el String de la BD de vuelta a DateTime
            fechaVencimiento: DateTime.parse(map['fechaVencimiento']),
            precioMensual: map['precioMensual'],
            tipoPlan: map['tipoPlan'],
          );
    }


}
