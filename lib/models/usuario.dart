class Usuario {
  final int? id;
  final String username;
  final String password;
  final String nombre;

  Usuario({
    this.id,
    required this.username,
    required this.password,
    required this.nombre,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'id': id,
      'username': username,
      'password': password,
      'nombre': nombre,
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
    );
  }
}
