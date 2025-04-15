import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user.dart';
import '../../services/admin_services.dart';

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
  bool? showOnlyActive; // null = todos, true = activos, false = inactivos

  final amarillo = const Color(0xFFFFC107);
  final negro = Colors.black;

  final List<String> oposiciones = [
    'todos',
    'BOMBERO',
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
      final matchesSearchQuery = user.nombreUsuario.toLowerCase().startsWith(searchQuery.toLowerCase());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Usuarios', style: GoogleFonts.poppins()),
        backgroundColor: amarillo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filtros desplegables
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
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
                      onChanged: (newValue) {
                        setState(() {
                          selectedOposicion = newValue!;
                        });
                      },
                      items: oposiciones.map((oposicion) {
                        return DropdownMenuItem<String>(
                          value: oposicion,
                          child: Text(oposicion),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
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
                      onChanged: (newValue) {
                        setState(() {
                          selectedRole = newValue!;
                        });
                      },
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

            // Campo de búsqueda
            Autocomplete<User>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                final filteredUsers = getFilteredUsers(textEditingValue.text);
                return filteredUsers.where((user) =>
                    user.nombreUsuario.toLowerCase().startsWith(textEditingValue.text.toLowerCase())).toList();
              },
              displayStringForOption: (User user) => user.nombreUsuario, // Cambiar aquí
              onSelected: (User selectedUser) {
                setState(() {
                  searchQuery = selectedUser.nombreUsuario; // Cambiar aquí
                });
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onSubmitted: (_) => onFieldSubmitted(),
                  decoration: InputDecoration(
                    labelText: 'Buscar por nombre de usuario',
                    hintText: 'Escribe el nombre de usuario...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: negro),
                    ),
                    suffixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Filtros por estado
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _filterByStatus(true),
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text('Activos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: showOnlyActive == true ? Colors.green : Colors.green.withOpacity(0.5),
                    foregroundColor: Colors.white,
                    elevation: showOnlyActive == true ? 6 : 2,
                    shadowColor: Colors.black,
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: () => _filterByStatus(false),
                  icon: const Icon(Icons.cancel, color: Colors.white),
                  label: const Text('Inactivos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: showOnlyActive == false ? Colors.red : Colors.red.withOpacity(0.5),
                    foregroundColor: Colors.white,
                    elevation: showOnlyActive == false ? 6 : 2,
                    shadowColor: Colors.black,
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
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: getFilteredUsers(searchQuery).length,
                itemBuilder: (context, index) {
                  final user = getFilteredUsers(searchQuery)[index];
                  return GestureDetector(
                    onDoubleTap: () => _toggleUserStatus(user.id),
                    child: Card(
                      color: user.active ? Colors.green : Colors.red,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              user.nombreUsuario,  // Cambiar aquí
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              user.oposicion,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white),
                            ),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _resetFilters,
        backgroundColor: amarillo,
        child: const Icon(Icons.refresh, color: Colors.black),
      ),
    );
  }
}
