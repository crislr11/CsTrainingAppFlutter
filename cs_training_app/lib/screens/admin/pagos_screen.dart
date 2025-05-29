import 'package:flutter/material.dart';
import 'package:cs_training_app/services/pago_service.dart';
import 'package:cs_training_app/models/user.dart';
import 'package:cs_training_app/models/pago.dart';
import '../../services/admin_services.dart';

class PagosScreen extends StatefulWidget {
  @override
  _PagosScreenState createState() => _PagosScreenState();
}

class _PagosScreenState extends State<PagosScreen> {
  final List<User> _users = [];
  final List<User> _filteredUsers = [];
  final List<Pago> _pagos = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  int? _selectedUserId;

  // Nuevo estado para filtro: null = todos, true = pagados, false = no pagados
  bool? _filterPagado;

  // Variables de color
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
      _filterPagado = pagado;
    });
    _applyFilters();
  }

  Future<void> _loadPagos(int userId) async {
    setState(() {
      _isLoading = true;
      _selectedUserId = userId;
    });
    try {
      final pagos = await PagoService().obtenerHistorialPagos(userId);
      setState(() {
        _pagos.clear();
        _pagos.addAll(pagos);

        // Ordenar los pagos por fecha (de mayor a menor)
        _pagos.sort((a, b) => b.fechaPago.compareTo(a.fechaPago)); // Ordenar de mayor a menor
      });
    } catch (e) {
      _showError('Error al cargar pagos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Método para crear un pago y actualizar el estado de "pagado" de un usuario
  Future<void> _crearPago() async {
    if (_selectedUserId == null) return;

    setState(() => _isLoading = true);
    try {
      // Creando el pago
      await PagoService().crearPago(_selectedUserId!);
      
      // Actualizando el estado del usuario
      setState(() {
        final userIndex = _users.indexWhere((user) => user.id == _selectedUserId);
        if (userIndex != -1) {
          _users[userIndex].pagado = true; // Cambiar a verde (pagado)
        }
      });

      // Recargar los pagos del usuario seleccionado
      await _loadPagos(_selectedUserId!);
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
      setState(() => _pagos.removeWhere((p) => p.id == pagoId));
      _showSuccess('Pago eliminado exitosamente');
    } catch (e) {
      _showError('Error al eliminar pago: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
                setState(() {
                  _searchController.text = selectedUser.nombreUsuario;
                  _loadPagos(selectedUser.id);
                });
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

          // Aquí añadimos los botones de filtro:
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _setFilter(true),
                    icon: const Icon(Icons.check_circle, color: Colors.white, size: 18),
                    label: const Text(
                      'Pagados',
                      style: TextStyle(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _filterPagado == true
                          ? Colors.green
                          : Colors.green.withOpacity(0.5),
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
                    label: const Text(
                      'No Pagados',
                      style: TextStyle(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _filterPagado == false
                          ? Colors.red
                          : Colors.red.withOpacity(0.5),
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
                    onTap: () => _loadPagos(user.id),
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
                                Text(
                                  user.role,
                                  style: TextStyle(color: Colors.white),
                                ),
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

      // ... El resto sin cambios ...
      bottomNavigationBar: _selectedUserId != null
          ? Container(
        height: 300,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(top: BorderSide(color: Colors.grey)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Historial de Pagos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: primaryColor,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => setState(() {
                    _pagos.clear();
                    _selectedUserId = null;
                  }),
                  color: primaryColor,
                ),
              ],
            ),
            Expanded(
              child: _pagos.isEmpty
                  ? Center(
                child: Text(
                  'No hay pagos registrados.',
                  style: TextStyle(color: Colors.white),
                ),
              )
                  : ListView.builder(
                itemCount: _pagos.length,
                itemBuilder: (context, index) {
                  final pago = _pagos[index];
                  return Card(
                    color: backgroundColor,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primaryColor,
                        child: Text(
                          '\$${pago.monto.toStringAsFixed(0)}',
                          style: TextStyle(color: backgroundColor),
                        ),
                      ),
                      title: Text(
                        _formatDate(pago.fechaPago),
                        style: TextStyle(color: Colors.white),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.white),
                        onPressed: () => _eliminarPago(pago.id),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _crearPago,
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
      )
          : null,
    );
  }
}