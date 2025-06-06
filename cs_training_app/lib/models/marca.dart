class Marca {
  final int? id;
  final int ejercicioId;
  final double valor;
  final DateTime fecha;
  final int userId;

  Marca({
    this.id,
    required this.userId,
    required this.ejercicioId,
    required this.valor,
    required this.fecha,
  });

  factory Marca.fromJson(Map<String, dynamic> json) {
    return Marca(
      id: json['id'],
      userId: json['userId'],
      ejercicioId: json['ejercicioId'],
      valor: (json['valor'] as num).toDouble(),
      fecha: DateTime.parse(json['fecha']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,       // Añade esto
      'userId': userId,
      'ejercicioId': ejercicioId,
      'valor': valor,
      'fecha': fecha.toIso8601String(),
    };
  }
}