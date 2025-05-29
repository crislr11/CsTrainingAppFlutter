import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/Opositor_service.dart';

class OpositorPorfileScreen extends StatefulWidget {
  const OpositorPorfileScreen({super.key});

  @override
  State<OpositorPorfileScreen> createState() => _OpositorProfileScreenState();
}

class _OpositorProfileScreenState extends State<OpositorPorfileScreen> {
  String _nombreCompleto = '';
  String _nombreUsuario = '';
  String _email = '';
  String _rol = '';
  int _userId = 0;
  File? _image;

  final OpositorService _service = OpositorService();

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombreCompleto = prefs.getString('nombre') ?? 'Usuario';
      _nombreUsuario = prefs.getString('nombreUsuario') ?? '';
      _email = prefs.getString('email') ?? 'Sin email';
      _rol = prefs.getString('role') ?? 'N/A';
      _userId = prefs.getInt('id') ?? 0;
    });

    // Cargar la foto del usuario después de obtener el ID
    if (_userId != 0) {
      await _loadUserPhoto();
    }
  }

  Future<void> _loadUserPhoto() async {
    try {
      // Primero verifica si hay una foto guardada localmente
      final prefs = await SharedPreferences.getInstance();
      final photoPath = prefs.getString('user_photo_path');

      if (photoPath != null && File(photoPath).existsSync()) {
        setState(() {
          _image = File(photoPath);
        });
        return;
      }

      // Si no hay local, intenta cargar del servidor
      final response = await _service.getUserPhoto(_userId.toString() as int);

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        // Guardar la imagen temporalmente
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/user_${_userId}_photo.jpg');
        await file.writeAsBytes(response.bodyBytes);

        // Guardar la ruta en SharedPreferences
        await prefs.setString('user_photo_path', file.path);

        setState(() {
          _image = file;
        });
      }
    } catch (e) {
      print('Error al cargar la foto del usuario: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      setState(() {
        _image = imageFile;
      });

      if (_userId == 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: ID de usuario inválido')),
        );
        return;
      }

      try {
        String result = await _service.uploadUserPhoto(_userId, _image!);

        // Guardar la imagen localmente después de subirla
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_photo_path', _image!.path);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result)),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir la foto: ${e.toString()}')),
        );
      }
    }
  }
  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de Usuario'),
        backgroundColor: const Color(0xFFFFC107),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFFFFC107),
                      backgroundImage: _image != null ? FileImage(_image!) : null,
                      child: _image == null
                          ? const Icon(Icons.person, size: 60, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _nombreCompleto,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '@$_nombreUsuario',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 20,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.email, color: Color(0xFFFFC107), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _email,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 20,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.badge, color: Color(0xFFFFC107), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _rol,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
