class AuthResponse {
  final String token;
  final String nombre;
  final String nombreUsuario;
  final String oposicion;
  final String role;
  final int id;

  AuthResponse({
    required this.token,
    required this.nombre,
    required this.nombreUsuario,
    required this.oposicion,
    required this.role,
    required this.id,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? "",
      nombre: json['nombre'] ?? "",
      nombreUsuario: json['nombreUsuario'] ?? "Desconocido",
      oposicion: json['oposicion'] ?? "No definida",
      role: json['role'] ?? "Usuario",
      id: json['id'] ?? 0,
    );
  }


  // Método para convertir el objeto a un JSON
  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'nombre': nombre,
      'nombreUsuario': nombreUsuario,
      'oposicion': oposicion,
      'role': role,
      'id': id,
    };
  }
}
