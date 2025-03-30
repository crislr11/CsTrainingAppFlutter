class RegisterRequest {
  final String username;
  final String password;
  final String email;
  final String role;
  final String oposicion;

  RegisterRequest({
    required this.username,
    required this.password,
    required this.email,
    required this.role,
    required this.oposicion,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'email': email,
      'role': role,
      'oposicion': oposicion,
    };
  }
}
