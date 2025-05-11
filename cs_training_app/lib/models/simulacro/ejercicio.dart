class Ejercicio {
  final int id;
  final String nombre;
  final double marca;

  Ejercicio({required this.id, required this.nombre, required this.marca});

  factory Ejercicio.fromJson(Map<String, dynamic> json) {
    return Ejercicio(
      id: json['id'],
      nombre: json['nombre'] ?? 'Nombre desconocido',
      marca: (json['marca'] != null) ? json['marca'].toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'marca':marca
    };
  }
}
