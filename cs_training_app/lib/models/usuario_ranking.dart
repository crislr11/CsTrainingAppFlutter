class UsuarioRanking {
  final String nombreUsuario;
  final double marca;

  UsuarioRanking({
    required this.nombreUsuario,
    required this.marca,
  });

  // Si quieres, puedes agregar métodos auxiliares, como fromJson/toJson:

  factory UsuarioRanking.fromJson(Map<String, dynamic> json) {
    return UsuarioRanking(
      nombreUsuario: json['nombreUsuario'] as String,
      marca: (json['marca'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombreUsuario': nombreUsuario,
      'marca': marca,
    };
  }
}
