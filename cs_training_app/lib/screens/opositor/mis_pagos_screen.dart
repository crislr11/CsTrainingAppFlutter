import 'package:flutter/material.dart';
import 'package:cs_training_app/models/pago.dart';
import 'package:cs_training_app/services/pago_service.dart';
import '../../widget/pago_card.dart';

class MisPagosScreen extends StatefulWidget {
  final int userId;

  const MisPagosScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _MisPagosScreenState createState() => _MisPagosScreenState();
}

class _MisPagosScreenState extends State<MisPagosScreen> {
  List<Pago> _pagos = [];
  bool _isLoading = false;

  final Color primaryColor = Colors.amber;
  final Color backgroundColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _loadPagos();
  }

  Future<void> _loadPagos() async {
    setState(() => _isLoading = true);
    try {
      final pagos = await PagoService().obtenerHistorialPagos(widget.userId);
      pagos.sort((a, b) => b.fechaPago.compareTo(a.fechaPago));
      setState(() {
        _pagos = pagos;
      });
    } catch (e) {
      _showError('Error al cargar pagos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pagos'),
        backgroundColor: const Color(0xFFFFC107),
      ),
      backgroundColor: backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pagos.isEmpty
          ? Center(
        child: Text(
          'No tienes pagos registrados.',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      )
          : ListView.builder(
        itemCount: _pagos.length,
        itemBuilder: (context, index) {
          final pago = _pagos[index];
          return PagoCard(
            pago: pago,
            primaryColor: primaryColor,
            backgroundColor: backgroundColor,
            // Si quieres agregar acciones como eliminar, las puedes agregar aquí
            // onDelete: () async { ... },
          );
        },
      ),
    );
  }
}
