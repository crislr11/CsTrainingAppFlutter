import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/Opositor_service.dart';
import '../../services/file_service.dart';
import '../../widget/built_entrenamiento_card.dart';
import 'entrenamientos_disponibles_screen.dart';
import 'mis_marcas_screen.dart';
import 'mis_pagos_screen.dart';
import 'mis_simulacros_screen.dart';
import 'ranking_screen.dart';

class OpositorPorfileScreen extends StatefulWidget {
  const OpositorPorfileScreen({super.key});

  @override
  State<OpositorPorfileScreen> createState() => _OpositorProfileScreenState();
}

class _OpositorProfileScreenState extends State<OpositorPorfileScreen>
    with WidgetsBindingObserver {
  // Datos del usuario
  String _nombreCompleto = '';
  String _nombreUsuario = '';
  String _email = '';
  String _oposicion = '';
  int _userId = 0;
  int _creditos = 0;

  // Gestión de imágenes
  File? _image;
  bool _loadingPhoto = false;

  // Entrenamientos
  List<dynamic> _entrenamientos = [];
  bool _loadingEntrenamientos = false;

  final OpositorService _opositorService = OpositorService();
  final FileService _fileService = FileService();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateCreditos();
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombreCompleto = prefs.getString('nombre') ?? 'Usuario';
      _nombreUsuario = prefs.getString('nombreUsuario') ?? '';
      _email = prefs.getString('email') ?? 'Sin email';
      _userId = prefs.getInt('id') ?? 0;
      _oposicion = prefs.getString('oposicion') ?? '';
      _creditos = prefs.getInt('creditos') ?? 0;
    });

    if (_userId != 0) {
      await _loadUserPhoto();
      await _loadEntrenamientos();
    }
  }

  Future<void> _updateCreditos() async {
    final prefs = await SharedPreferences.getInstance();
    final nuevosCreditos = prefs.getInt('creditos') ?? 0;
    if (mounted && nuevosCreditos != _creditos) {
      setState(() => _creditos = nuevosCreditos);
    }
  }

  Future<void> _loadEntrenamientos() async {
    if (_userId == 0) return;

    setState(() => _loadingEntrenamientos = true);

    try {
      final entrenamientos = await _opositorService.getEntrenamientosDelOpositor(_userId);
      if (mounted) {
        setState(() => _entrenamientos = entrenamientos);
      }
    } catch (e) {
      if (!e.toString().contains('404') && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar entrenamientos: $e')),
        );
      }
      if (mounted) {
        setState(() => _entrenamientos = []);
      }
    } finally {
      if (mounted) {
        setState(() => _loadingEntrenamientos = false);
      }
    }
  }

  Future<void> _loadUserPhoto() async {
    if (!mounted) return;
    setState(() => _loadingPhoto = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final photoPath = prefs.getString('user_photo_path');

      // Verificar caché local
      if (photoPath != null && await File(photoPath).exists()) {
        if (mounted) {
          setState(() {
            _image = File(photoPath);
            _loadingPhoto = false;
          });
        }
        return;
      }

      // Descargar del servidor
      try {
        final photoBytes = await _fileService.downloadUserPhoto(_userId);
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/user_${_userId}_photo.jpg');
        await file.writeAsBytes(photoBytes);

        await prefs.setString('user_photo_path', file.path);

        if (mounted) {
          setState(() {
            _image = file;
            _loadingPhoto = false;
          });
        }
      } catch (e) {
        print('Error descargando foto: $e');
        if (mounted) {
          setState(() => _loadingPhoto = false);
        }
      }
    } catch (e) {
      print('Error cargando foto: $e');
      if (mounted) {
        setState(() => _loadingPhoto = false);
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null || !mounted) return;

    final imageFile = File(pickedFile.path);
    setState(() => _image = imageFile);

    try {
      await _fileService.uploadFile(_userId, imageFile);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_photo_path', imageFile.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto actualizada correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir foto: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    final photoPath = prefs.getString('user_photo_path');

    if (photoPath != null) {
      try {
        await File(photoPath).delete();
      } catch (e) {
        print('Error eliminando foto: $e');
      }
    }

    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.5),
          offset: const Offset(0, 5),
          blurRadius: 12,
        )],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _pickAndUploadImage,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFFFFC107),
              backgroundImage: _image != null ? FileImage(_image!) : null,
              child: _loadingPhoto
                  ? const CircularProgressIndicator(color: Colors.white)
                  : _image == null
                  ? const Icon(Icons.person, size: 40, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nombreCompleto,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _nombreUsuario,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                _buildUserDetail(Icons.email, _email),
                const SizedBox(height: 8),
                _buildUserDetail(Icons.school, _formatearOposicion(_oposicion)),
                const SizedBox(height: 8),
                _buildUserDetail(Icons.monetization_on, 'Créditos: $_creditos'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFFC107), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 18),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: Colors.black),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntrenamientosList() {
    if (_loadingEntrenamientos) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_entrenamientos.isEmpty) {
      return Center(
        child: Column(
          children: [
            const Text('No tienes entrenamientos asignados'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EntrenamientosDisponiblesScreen(oposicion: _oposicion),
                ),
              ).then((_) => _updateCreditos()),
              child: const Text('Ver entrenamientos disponibles'),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: ListView.separated(
        itemCount: _entrenamientos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final entrenamiento = _entrenamientos[index];
          return EntrenamientoCard(
            entrenamiento: entrenamiento,
            inscrito: true,
            onDesapuntarse: () => _opositorService.desapuntarseDeEntrenamiento(
                entrenamiento.id!, _userId),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < 0 && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RankingScreen(oposicion: _oposicion),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Perfil de Usuario',
            style: GoogleFonts.rubik(fontWeight: FontWeight.w700),
          ),
          backgroundColor: const Color(0xFFFFC107),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _updateCreditos();
                  _loadUserData();
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(
                      Icons.fitness_center,
                      'Clases',
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EntrenamientosDisponiblesScreen(oposicion: _oposicion),
                        ),
                      ),
                    ),
                    _buildActionButton(
                      Icons.assignment,
                      'Simulacros',
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MisSimulacrosScreen(userId: _userId),
                        ),
                      ),
                    ),
                    _buildActionButton(
                      Icons.attach_money,
                      'Pagos',
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MisPagosScreen(userId: _userId),
                        ),
                      ),
                    ),
                    _buildActionButton(
                      Icons.playlist_add_check,
                      'Mis Marcas',
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MisMarcasScreen(userId: _userId),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildEntrenamientosList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatearOposicion(String oposicion) {
    return oposicion.replaceAll('_', ' ').toUpperCase();
  }
}