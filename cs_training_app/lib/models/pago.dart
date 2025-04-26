class Pago {
  final int id;
  final double monto;
  final DateTime fechaPago;
  final int userId;

  Pago({
    required this.id,
    required this.monto,
    required this.fechaPago,
    required this.userId,
  });

  factory Pago.fromJson(Map<String, dynamic> json) {
    return Pago(
      id: json['id'] ?? 0,
      monto: (json['monto'] as num?)?.toDouble() ?? 0.0,
      fechaPago: json['fechaPago'] != null
          ? DateTime.parse(json['fechaPago'])
          : DateTime.now(),
      userId: json['userId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'monto': monto,
      'fechaPago': fechaPago.toIso8601String(),
      'userId': userId,
    };
  }
}
