import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class UsuariosScreen extends StatefulWidget {
  @override
  _UsuariosScreenState createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  List<Map<String, dynamic>> usuarios = [
    {'id': 1, 'name': 'Juan Pérez', 'role': 'u', 'actived': 1, 'isPaid': true, 'photo': 'https://via.placeholder.com/150'},
    {'id': 2, 'name': 'Ana García', 'role': 'u', 'actived': 0, 'isPaid': false, 'photo': 'https://via.placeholder.com/150'},
    {'id': 3, 'name': 'Luis Rodríguez', 'role': 'o', 'actived': 1, 'isPaid': true, 'photo': 'https://via.placeholder.com/150'},
    {'id': 4, 'name': 'Marta López', 'role': 'o', 'actived': 0, 'isPaid': false, 'photo': 'https://via.placeholder.com/150'},
  ];

  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text('¿Estás seguro de que quieres eliminar este usuario?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // Función para mostrar la pestaña de edición con un diseño más bonito
  void _showEditUserDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController nameController = TextEditingController(text: user['name']);
        TextEditingController roleController = TextEditingController(text: user['role']);

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editar Usuario',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    labelStyle: TextStyle(color: Colors.blue.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade600),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: roleController,
                  decoration: InputDecoration(
                    labelText: 'Rol',
                    labelStyle: TextStyle(color: Colors.blue.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade600),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);  // Cerrar el cuadro de diálogo
                      },
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          user['name'] = nameController.text;
                          user['role'] = roleController.text;
                        });
                        Navigator.pop(context);  // Cerrar el cuadro de diálogo
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        'Guardar',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    var id = user['id'];
    var name = user['name'];
    var role = user['role'] == 'u' ? 'Usuario' : 'Organizador';
    var isActive = user['actived'] == 1;
    var isPaid = user['isPaid'];
    var photoUrl = user['photo'];

    Color cardColor = isPaid ? Colors.green.shade200 : Colors.red.shade200;
    String paymentStatus = isPaid ? 'Pagado' : 'No pagado';

    return Slidable(
      key: ValueKey(id),
      startActionPane: ActionPane(
        motion: ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              setState(() {
                user['actived'] = isActive ? 0 : 1;
              });
            },
            backgroundColor: isActive ? Colors.blue.shade300 : Colors.blue.shade600,
            icon: Icons.check,
            borderRadius: BorderRadius.circular(20),
          ),
          SlidableAction(
            onPressed: (context) {
              setState(() {
                user['isPaid'] = !isPaid;
              });
            },
            backgroundColor: isPaid ? Colors.green.shade400 : Colors.red.shade400,
            icon: Icons.attach_money,
            borderRadius: BorderRadius.circular(20),
          ),
          SlidableAction(
            onPressed: (context) async {
              bool confirmed = await _showDeleteConfirmationDialog();
              if (confirmed) {
                setState(() {
                  usuarios.removeWhere((element) => element['id'] == id);
                });
              }
            },
            backgroundColor: Colors.grey.shade800,
            icon: Icons.delete,
            borderRadius: BorderRadius.circular(20),
          ),
        ],
      ),
      child: GestureDetector(
        onDoubleTap: () {
          _showEditUserDialog(user);
        },
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          elevation: 4,
          color: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16.0),
            leading: CircleAvatar(
              backgroundImage: NetworkImage(photoUrl),
              radius: 30,
            ),
            title: Text(
              '$name',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isActive ? 'Activo' : 'Desactivado',
                  style: TextStyle(
                    fontSize: 14,
                    color: isActive ? Colors.green : Colors.red,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  paymentStatus,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: usuarios.length,
        itemBuilder: (context, index) {
          return _buildUserCard(usuarios[index]);
        },
      ),
    );
  }
}
