

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user.dart';
import '../../services/admin_services.dart';
import '../../services/file_service.dart';
import 'dart:typed_data' as typed_data;



class ActivarUsuarios extends StatefulWidget {
  const ActivarUsuarios({super.key});

  @override
  _ActivarUsuariosScreenState createState() => _ActivarUsuariosScreenState();
}

class _ActivarUsuariosScreenState extends State<ActivarUsuarios> {
  List<User> users = [];
  String selectedOposicion = 'todos';
  String selectedRole = 'todos';
  String searchQuery = '';
  bool? showOnlyActive;
  final FileService _fileService = FileService();

  final amarillo = const Color(0xFFFFC107);
  final negro = Colors.black;

  final List<String> oposiciones = [
    'todos',
    'POLICIA_NACIONAL',
    'POLICIA_LOCAL',
    'SUBOFICIAL',
    'GUARDIA_CIVIL',
    'SERVICIO_VIGILANCIA_ADUANERA'
  ];

  final List<String> roles = ['todos', 'PROFESOR', 'OPOSITOR'];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final allUsers = await AdminService().getAllUsers();
      setState(() {
        users = (allUsers ?? []).where((user) => user.role != 'ADMIN').toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los usuarios: $e')),
      );
    }
  }

  List<User> getFilteredUsers(String searchQuery) {
    return users.where((user) {
      final matchesOposicion = selectedOposicion == 'todos' || user.oposicion == selectedOposicion;
      final matchesRole = selectedRole == 'todos' || user.role == selectedRole;
      final matchesSearchQuery = user.nombreUsuario.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesActive = showOnlyActive == null || user.active == showOnlyActive;
      return matchesOposicion && matchesRole && matchesSearchQuery && matchesActive;
    }).toList();
  }

  Future<void> _toggleUserStatus(int id) async {
    try {
      await AdminService().toggleUserStatus(id);
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cambiar el estado del usuario: $e')),
      );
    }
  }

  Future<void> _editUserDialog(User user) async {
    final nombreController = TextEditingController(text: user.nombreUsuario);
    final creditosController = TextEditingController(text: user.creditos.toString());
    bool pagado = user.pagado;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar usuario'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de usuario',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: creditosController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Créditos',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('¿Pagado?', style: TextStyle(fontSize: 16)),
                    Checkbox(
                      value: pagado,
                      onChanged: (value) {
                        setState(() {
                          pagado = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final updatedUserData = {
                  'nombre': nombreController.text,
                  'creditos': int.tryParse(creditosController.text) ?? 0,
                  'pagado': pagado,
                };

                await AdminService().updateUser(user.id, updatedUserData);
                Navigator.pop(context);
                _loadUsers();
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al actualizar el usuario: $e')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      selectedOposicion = 'todos';
      selectedRole = 'todos';
      searchQuery = '';
      showOnlyActive = null;
    });
  }

  void _filterByStatus(bool active) {
    setState(() {
      showOnlyActive = showOnlyActive == active ? null : active;
    });
  }

  Future<void> _confirmDeleteUser(int id) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar perfil'),
          content: const Text('¿Estás seguro de que quieres eliminar este perfil?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await AdminService().deleteUser(id);
        _loadUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario eliminado correctamente')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar el usuario: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Usuarios', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: amarillo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filtros superiores
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: negro),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      underline: const SizedBox(),
                      value: selectedOposicion,
                      onChanged: (newValue) => setState(() => selectedOposicion = newValue!),
                      items: oposiciones.map((oposicion) {
                        return DropdownMenuItem<String>(
                          value: oposicion,
                          child: Text(oposicion),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: negro),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      underline: const SizedBox(),
                      value: selectedRole,
                      onChanged: (newValue) => setState(() => selectedRole = newValue!),
                      items: roles.map((role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(role),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Barra de búsqueda
            TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                labelText: 'Buscar usuario',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Filtros de estado
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilterChip(
                  label: const Text('Activos'),
                  selected: showOnlyActive == true,
                  onSelected: (_) => _filterByStatus(true),
                  selectedColor: Colors.green,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: showOnlyActive == true ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(width: 20),
                FilterChip(
                  label: const Text('Inactivos'),
                  selected: showOnlyActive == false,
                  onSelected: (_) => _filterByStatus(false),
                  selectedColor: Colors.red,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: showOnlyActive == false ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Lista de usuarios
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 0.85,
                ),
                itemCount: getFilteredUsers(searchQuery).length,
                itemBuilder: (context, index) {
                  final user = getFilteredUsers(searchQuery)[index];
                  return _buildUserCard(user);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _resetFilters,
        backgroundColor: amarillo,
        child: const Icon(Icons.refresh, color: Colors.black),
      ),
    );
  }

  Widget _buildUserCard(User user) {
    return FutureBuilder<typed_data.Uint8List>(
      future: _fileService.downloadUserPhoto(user.id),
      builder: (context, snapshot) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () => _editUserDialog(user),
            onLongPress: () => _toggleUserStatus(user.id),
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: user.active ? Colors.green[50] : Colors.red[50],
              ),
              child: Stack(
                children: [
                  // Botón eliminar en la esquina superior derecha
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeleteUser(user.id),
                    ),
                  ),
                  // Contenido centrado
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: user.active ? Colors.green : Colors.red,
                                width: 3,
                              ),
                            ),
                            child: ClipOval(
                              child: snapshot.hasData
                                  ? Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildDefaultAvatar(),
                              )
                                  : _buildDefaultAvatar(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user.nombreUsuario,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            _formatOposicion(user.oposicion),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }




  Widget _buildDefaultAvatar() {
    return const Icon(Icons.person, size: 50, color: Colors.grey);
  }

  String _formatOposicion(String oposicion) {
    return oposicion.replaceAll('_', ' ').toLowerCase();
  }
}