import 'package:flutter/material.dart';
import 'package:cs_training_app/services/pago_service.dart';
import 'package:cs_training_app/models/user.dart';
import 'package:cs_training_app/models/pago.dart';
import '../../services/admin_services.dart';
import '../../widget/pago_card.dart';

class PagosScreen extends StatefulWidget {
  @override
  _PagosScreenState createState() => _PagosScreenState();
}

class _PagosScreenState extends State<PagosScreen> {
  final List<User> _users = [];
  final List<User> _filteredUsers = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  bool? _filterPagado;

  final Color primaryColor = Colors.amber;
  final Color backgroundColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await AdminService().getAllUsers();
      setState(() {
        _users.clear();
        _users.addAll(users.where((user) => user.role == 'OPOSITOR'));
        _applyFilters();
      });
    } catch (e) {
      _showError('Error al cargar usuarios: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterUsers() {
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers.clear();
      _filteredUsers.addAll(
        _users.where((user) {
          final matchesSearch = user.nombreUsuario.toLowerCase().contains(query);
          final matchesFilter = _filterPagado == null || user.pagado == _filterPagado;
          return matchesSearch && matchesFilter;
        }),
      );
    });
  }

  void _setFilter(bool? pagado) {
    setState(() {
      if (_filterPagado == pagado) {
        _filterPagado = null;
      } else {
        _filterPagado = pagado;
      }
    });
    _applyFilters();
  }


  Future<List<Pago>> _loadPagos(int userId) async {
    try {
      final pagos = await PagoService().obtenerHistorialPagos(userId);
      pagos.sort((a, b) => b.fechaPago.compareTo(a.fechaPago));
      return pagos;
    } catch (e) {
      _showError('Error al cargar pagos: $e');
      return [];
    }
  }

  Future<void> _crearPago(int userId) async {
    setState(() => _isLoading = true);
    try {
      await PagoService().crearPago(userId);
      final userIndex = _users.indexWhere((u) => u.id == userId);
      if (userIndex != -1) {
        setState(() {
          _users[userIndex].pagado = true;
          _applyFilters();
        });
      }
      _showSuccess('Pago creado exitosamente');
    } catch (e) {
      _showError('Error al crear pago: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminarPago(int pagoId) async {
    setState(() => _isLoading = true);
    try {
      await PagoService().eliminarPago(pagoId);
      _showSuccess('Pago eliminado exitosamente');
    } catch (e) {
      _showError('Error al eliminar pago: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _openPagosModal(User user) async {
    final pagos = await _loadPagos(user.id);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Barra para arrastrar
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Text(
                    'Historial de Pagos de ${user.nombreUsuario}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: pagos.isEmpty
                        ? Center(
                      child: Text(
                        'No hay pagos registrados.',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                        : ListView.builder(
                      controller: scrollController,
                      itemCount: pagos.length,
                      itemBuilder: (context, index) {
                        final pago = pagos[index];
                        return PagoCard(
                          pago: pago,
                          onDelete: () async {
                            await _eliminarPago(pago.id);
                            pagos.removeAt(index);
                            setState(() {});
                          },
                          primaryColor: primaryColor,
                          backgroundColor: backgroundColor,
                        );
                      },
                    ),
                  ),

                  ElevatedButton(
                    onPressed: () async {
                      await _crearPago(user.id);
                      // Recargar la lista de pagos tras agregar uno
                      final nuevosPagos = await _loadPagos(user.id);
                      if (mounted) {
                        Navigator.pop(context);
                        _openPagosModal(user); // reabrir modal con datos actualizados
                      }
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(primaryColor),
                    ),
                    child: Text(
                      'Agregar Nuevo Pago',
                      style: TextStyle(color: backgroundColor),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Pagos'),
        backgroundColor: const Color(0xFFFFC107),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Autocomplete<User>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                final query = textEditingValue.text.toLowerCase();
                return _filteredUsers.where((user) => user.nombreUsuario.toLowerCase().contains(query)).toList();
              },
              displayStringForOption: (User user) => user.nombreUsuario,
              onSelected: (User selectedUser) {
                _openPagosModal(selectedUser);
                _searchController.text = selectedUser.nombreUsuario;
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onSubmitted: (_) => onFieldSubmitted(),
                  decoration: InputDecoration(
                    labelText: 'Buscar usuario',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _setFilter(true),
                    icon: const Icon(Icons.check_circle, color: Colors.white, size: 18),
                    label: const Text('Pagados', style: TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _filterPagado == true ? Colors.green : Colors.green.withOpacity(0.5),
                      foregroundColor: Colors.white,
                      elevation: _filterPagado == true ? 6 : 2,
                      shadowColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _setFilter(false),
                    icon: const Icon(Icons.cancel, color: Colors.white, size: 18),
                    label: const Text('No Pagados', style: TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _filterPagado == false ? Colors.red : Colors.red.withOpacity(0.5),
                      foregroundColor: Colors.white,
                      elevation: _filterPagado == false ? 6 : 2,
                      shadowColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading && _filteredUsers.isEmpty
                ? Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                ? Center(child: Text('No se encontraron usuarios'))
                : ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: user.pagado ? Colors.green : Colors.red,
                  child: InkWell(
                    onTap: () => _openPagosModal(user),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: primaryColor,
                            child: Text(
                              user.nombreUsuario[0],
                              style: TextStyle(color: backgroundColor),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.nombreUsuario,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: primaryColor,
                                  ),
                                ),
                                Text(user.role, style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: primaryColor),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
