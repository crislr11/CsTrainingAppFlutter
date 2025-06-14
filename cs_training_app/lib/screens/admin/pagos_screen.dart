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

class _PagosScreenState extends State<PagosScreen> with SingleTickerProviderStateMixin {
  final List<User> _users = [];
  final List<User> _filteredUsers = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool? _filterPagado;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final Color primaryColor = Colors.amber;
  final Color backgroundColor = Colors.black;
  final Color cardColor = Color(0xFF1A1A1A);
  final Color surfaceColor = Color(0xFF2D2D2D);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadUsers();
    _searchController.addListener(_filterUsers);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
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
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _openPagosModal(User user) async {
    final pagos = await _loadPagos(user.id);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Barra para arrastrar mejorada
                    Container(
                      width: 50,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[500],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    // Header del modal mejorado
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primaryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: primaryColor,
                            child: Text(
                              user.nombreUsuario[0],
                              style: TextStyle(
                                color: backgroundColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Historial de Pagos',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: primaryColor,
                                  ),
                                ),
                                Text(
                                  user.nombreUsuario,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Expanded(
                      child: pagos.isEmpty
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.payment_outlined,
                              size: 64,
                              color: Colors.grey[600],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No hay pagos registrados',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                          : ListView.builder(
                        controller: scrollController,
                        itemCount: pagos.length,
                        itemBuilder: (context, index) {
                          final pago = pagos[index];
                          return AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            margin: EdgeInsets.only(bottom: 12),
                            child: PagoCard(
                              pago: pago,
                              onDelete: () async {
                                await _eliminarPago(pago.id);
                                pagos.removeAt(index);
                                setState(() {});
                              },
                              primaryColor: primaryColor,
                              backgroundColor: backgroundColor,
                            ),
                          );
                        },
                      ),
                    ),

                    // Botón mejorado
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 16),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _crearPago(user.id);
                          final nuevosPagos = await _loadPagos(user.id);
                          if (mounted) {
                            Navigator.pop(context);
                            _openPagosModal(user);
                          }
                        },
                        icon: Icon(Icons.add_circle_outline, color: backgroundColor),
                        label: Text(
                          'Agregar Nuevo Pago',
                          style: TextStyle(
                            color: backgroundColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Gestión de Pagos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: backgroundColor,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(Icons.refresh_rounded, color: backgroundColor),
              onPressed: _loadUsers,
              tooltip: 'Actualizar',
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Header sin gradiente
            Container(
              color: backgroundColor,
              child: Column(
                children: [
                  // Barra de búsqueda mejorada
                  Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Autocomplete<User>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        final query = textEditingValue.text.toLowerCase();
                        return _filteredUsers
                            .where((user) => user.nombreUsuario.toLowerCase().contains(query))
                            .toList();
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
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Buscar usuario',
                            labelStyle: TextStyle(color: Colors.white70),
                            prefixIcon: Icon(Icons.search_rounded, color: primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                        );
                      },
                    ),
                  ),

                  // Filtros mejorados
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            child: ElevatedButton.icon(
                              onPressed: () => _setFilter(true),
                              icon: Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              label: Text(
                                'Pagados',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _filterPagado == true
                                    ? Colors.green.shade600
                                    : Colors.green.withOpacity(0.3),
                                foregroundColor: Colors.white,
                                elevation: _filterPagado == true ? 8 : 2,
                                shadowColor: Colors.green.withOpacity(0.5),
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            child: ElevatedButton.icon(
                              onPressed: () => _setFilter(false),
                              icon: Icon(
                                Icons.cancel_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              label: Text(
                                'No Pagados',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _filterPagado == false
                                    ? Colors.red.shade600
                                    : Colors.red.withOpacity(0.3),
                                foregroundColor: Colors.white,
                                elevation: _filterPagado == false ? 8 : 2,
                                shadowColor: Colors.red.withOpacity(0.5),
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Lista de usuarios mejorada
            Expanded(
              child: _isLoading && _filteredUsers.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Cargando usuarios...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              )
                  : _filteredUsers.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_search_rounded,
                      size: 64,
                      color: Colors.grey[600],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No se encontraron usuarios',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = _filteredUsers[index];
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    margin: EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: user.pagado
                                ? [Colors.green.shade700, Colors.green.shade600]
                                : [Colors.red.shade700, Colors.red.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: (user.pagado ? Colors.green : Colors.red)
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () => _openPagosModal(user),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Hero(
                                  tag: 'avatar_${user.id}',
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: primaryColor,
                                    child: Text(
                                      user.nombreUsuario[0].toUpperCase(),
                                      style: TextStyle(
                                        color: backgroundColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            user.pagado
                                                ? Icons.check_circle_rounded
                                                : Icons.pending_rounded,
                                            size: 16,
                                            color: Colors.white70,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            user.pagado ? 'Pagado' : 'Pendiente',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}