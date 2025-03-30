class AuthResponse {
  final String token;
  final String nombre;
  final String oposicion;
  final String role;

  AuthResponse({
    required this.token,
    required this.nombre,
    required this.oposicion,
    required this.role,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
      nombre: json['nombre'],
      oposicion: json['oposicion'],
      role: json['role'],
    );
  }
}
