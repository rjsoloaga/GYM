class Usuario {
  final int? id;
  final String username;
  final String password;
  final String nombre;
  final String rol; // 'admin' o 'coach'

  Usuario({
    this.id,
    required this.username,
    required this.password,
    required this.nombre,
    this.rol = 'admin', // Por defecto admin
  });

  // Método para verificar si el usuario puede editar
  bool get puedeEditar => rol == 'admin';
  
  // Método para verificar si el usuario puede eliminar
  bool get puedeEliminar => rol == 'admin';
  
  // Método para verificar si el usuario es coach
  bool get esCoach => rol == 'coach';

  Map<String, dynamic> toMap() {
    final map = {
      'id': id,
      'username': username,
      'password': password,
      'nombre': nombre,
      'rol': rol,
    };
    if (id == null) {
      map.remove('id');
    }
    return map;
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      nombre: map['nombre'],
      rol: map['rol'] ?? 'admin', // Por defecto admin si no existe
    );
  }
}
