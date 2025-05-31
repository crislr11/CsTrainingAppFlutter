class Marca {
  final int ejercicioId;
  final double valor;
  final DateTime fecha;
  final int userId;

  Marca({
    required this.userId,
    required this.ejercicioId,
    required this.valor,
    required this.fecha,
  });

  factory Marca.fromJson(Map<String, dynamic> json) {
    return Marca(
      userId: json['userId'],
      ejercicioId: json['ejercicioId'],
      valor: (json['valor'] as num).toDouble(),
      fecha: DateTime.parse(json['fecha']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'ejercicioId': ejercicioId,
      'valor': valor,
      'fecha': fecha.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Marca(userId: $userId, ejercicioId: $ejercicioId, valor: $valor, fecha: $fecha)';
  }
}
