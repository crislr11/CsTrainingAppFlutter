class Entrenamiento {
  final int id;
  final String oposicion;
  final List<String> profesores;
  final List<String> alumnos;
  final String fecha;
  final String lugar;

  Entrenamiento({
    required this.id,
    required this.oposicion,
    required this.profesores,
    required this.alumnos,
    required this.fecha,
    required this.lugar,
  });

  factory Entrenamiento.fromJson(Map<String, dynamic> json) {
    return Entrenamiento(
      id: json['id'],
      oposicion: json['oposicion'],
      profesores: List<String>.from(json['profesores']),
      alumnos: List<String>.from(json['alumnos']),
      fecha: json['fecha'],
      lugar: json['lugar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'oposicion': oposicion,
      'profesores': profesores,
      'alumnos': alumnos,
      'fecha': fecha,
      'lugar': lugar,
    };
  }
}
