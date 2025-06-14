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

  Future<void> _handleDesapuntarse(int entrenamientoId) async {
    try {
      final resultado = await _opositorService.desapuntarseDeEntrenamiento(entrenamientoId, _userId);

      if (resultado != null && mounted) {
        // Actualizar créditos y entrenamientos
        await _updateCreditos();
        await _loadEntrenamientos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al desapuntarse: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _pickAndUploadImage,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFC107).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 38,
                backgroundColor: const Color(0xFFFFC107),
                backgroundImage: _image != null ? FileImage(_image!) : null,
                child: _loadingPhoto
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : _image == null
                    ? const Icon(Icons.person_add, size: 35, color: Colors.black87)
                    : null,
              ),
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
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.verified_user,
                      color: Color(0xFFFFC107),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _nombreUsuario,
                        style: const TextStyle(
                          color: Color(0xFFFFC107),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildUserDetail(Icons.email_outlined, _email),
                const SizedBox(height: 6),
                _buildUserDetail(Icons.school_outlined, _formatearOposicion(_oposicion)),
                const SizedBox(height: 10),
                _buildCreditosDetail(),
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
        Icon(icon, color: const Color(0xFFFFC107), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCreditosDetail() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFC107).withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.stars,
            color: Color(0xFFFFC107),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Créditos: ',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '$_creditos',
            style: const TextStyle(
              color: Color(0xFFFFC107),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: Colors.black),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntrenamientosList() {
    if (_loadingEntrenamientos) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFFC107),
            strokeWidth: 3,
          ),
        ),
      );
    }

    if (_entrenamientos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.fitness_center,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            const Text(
              'No tienes entrenamientos asignados',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EntrenamientosDisponiblesScreen(oposicion: _oposicion),
                ),
              ).then((_) => _updateCreditos()),
              icon: const Icon(Icons.search, size: 16),
              label: const Text(
                'Ver entrenamientos',
                style: TextStyle(fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: Color(0xFFFFC107),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Mis Entrenamientos (${_entrenamientos.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            itemCount: _entrenamientos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final entrenamiento = _entrenamientos[index];
              return EntrenamientoCard(
                  entrenamiento: entrenamiento,
                  inscrito: true,
                  onDesapuntarse: () => _handleDesapuntarse(entrenamiento.id!)
              );
            },
          ),
        ),
      ],
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
            style: GoogleFonts.rubik(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          backgroundColor: const Color(0xFFFFC107),
          foregroundColor: Colors.black,
          elevation: 0,
          toolbarHeight: 50,
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.refresh, size: 18),
              ),
              onPressed: () {
                setState(() {
                  _updateCreditos();
                  _loadUserData();
                });
              },
              tooltip: 'Actualizar',
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.logout, size: 18, color: Colors.red),
              ),
              onPressed: _logout,
              tooltip: 'Salir',
            ),
          ],
        ),
        body: Column(
          children: [
            // Header del perfil
            _buildProfileHeader(),

            // Contenido principal en Expanded
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Botones de acción
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            Icons.fitness_center,
                            'Clases',
                                () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EntrenamientosDisponiblesScreen(oposicion: _oposicion),
                              ),
                            ).then((_) => _updateCreditos()),
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
                            'Marcas',
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

                    // Lista de entrenamientos
                    _buildEntrenamientosList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatearOposicion(String oposicion) {
    return oposicion.replaceAll('_', ' ').toUpperCase();
  }
}