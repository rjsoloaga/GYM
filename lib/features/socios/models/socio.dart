//Definimos la clase, nuestro modelo para crear los objetos 'Socio'
class Socio {
    final int? id;
    final String nombreCompleto;
    final String dni;
    final String telefono;
    final String email;
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
        required this.email,
        required this.fechaInicio,
        required this.fechaVencimiento,
        required this.precioMensual,
        required this.tipoPlan,
    });

    //Metodo getter para obtener el estado de la cuota
    String get estadoCuota {
      final hoy = DateTime.now();
      final diasHastaVencimiento = fechaVencimiento.difference(hoy).inDays;

      if (diasHastaVencimiento > 7) { 
        return 'Verde';        // Más de 7 días - TODO BIEN
      } else if (diasHastaVencimiento >= 0) {
        return 'Ambar';        // 0-7 días - POR VENCER
      } else {
        return 'Rojo';         // Vencido - MOROSO
      }
    }

    bool get necesitaNotificacion {
      final hoy = DateTime.now();
      final diasHastaVencimiento = fechaVencimiento.difference(hoy).inDays;
      return diasHastaVencimiento <= 7 && diasHastaVencimiento >= 0;
    }

    //Metodo para crear una copia del objeto 'Socio' con los valores modificados
    //Sirve para editar los valores de un 'Socio'
    Socio copyWith({
        int? id,
        String? nombreCompleto,
        String? dni,
        String? telefono,
        String? email,
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
            email: email ?? this.email,
            fechaInicio: fechaInicio ?? this.fechaInicio,
            fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
            precioMensual: precioMensual ?? this.precioMensual,
            tipoPlan: tipoPlan ?? this.tipoPlan,
        );
    }

    //Metodo para convertir un socio a un Map(Diccionario)
    Map<String, dynamic> toMap() {
      return {
        'id': id,
        'nombreCompleto': nombreCompleto,
        'dni': dni,
        'telefono': telefono,
        'email': email,
        'fechaInicio': fechaInicio.toIso8601String(),
        'fechaVencimiento': fechaVencimiento.toIso8601String(),
        'precioMensual': precioMensual,
        'tipoPlan': tipoPlan,
        // 'activo' lo maneja la BD o incluir si lo tienes en el modelo
      };
    }

    // Factory para crear Socio desde Map (útil al leer de la BD)
    factory Socio.fromMap(Map<String, dynamic> map) {
      return Socio(
        id: map['id'] as int?,
        nombreCompleto: map['nombreCompleto'] as String? ?? '',
        dni: map['dni'] as String? ?? '',
        telefono: map['telefono'] as String? ?? '',
        email: map['email'] as String? ?? '',
        fechaInicio: DateTime.parse(map['fechaInicio'] as String),
        fechaVencimiento: DateTime.parse(map['fechaVencimiento'] as String),
        precioMensual: (map['precioMensual'] as num?)?.toDouble() ?? 0.0,
        tipoPlan: map['tipoPlan'] as String? ?? '',
      );
    }
}
