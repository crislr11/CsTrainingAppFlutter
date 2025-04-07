import 'package:cs_training_app/screens/profesor/mis_clases_screen.dart';
import 'package:cs_training_app/screens/user/list_clases_opo_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin/clases_screen.dart';
import 'admin/usuarios_screen.dart';
import 'user/profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _role = "OPOSITOR";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('role') ?? "ADMIN";
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _screens = [];
    List<BottomNavigationBarItem> _navItems = [];
    String _appBarTitle = "Inicio";

    switch (_role) {
      case "ADMIN":
        _screens = [
          Center(child: Text("Inicio Admin")),
          UsuariosScreen(),
          ClasesScreen(),
        ];
        _navItems = [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Usuarios"),
          BottomNavigationBarItem(icon: Icon(Icons.class_), label: "Clases"),
        ];
        _appBarTitle = _selectedIndex == 0
            ? "Inicio"
            : _selectedIndex == 1
            ? "Usuarios"
            : "Clases";
        break;

      case "PROFESOR":
        _screens = [
          MisClasesScreen(),
          ProfileScreen(),
        ];
        _navItems = [
          BottomNavigationBarItem(icon: Icon(Icons.school), label: "Mis Clases"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ];
        _appBarTitle = _selectedIndex == 0 ? "Mis Clases" : "Perfil";
        break;

      case "OPOSITOR":
      default:
        _screens = [
          MisClasesScreen(),
          ListClasesOpoScreen(),
          ProfileScreen(),
        ];
        _navItems = [
          BottomNavigationBarItem(icon: Icon(Icons.event_note), label: "Mis Clases"),
          BottomNavigationBarItem(icon: Icon(Icons.class_), label: "Clases"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ];
        _appBarTitle = _selectedIndex == 0
            ? "Mis Clases"
            : _selectedIndex == 1
            ? "Clases"
            : "Perfil";
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _appBarTitle,
          style: TextStyle(color: Color(0xFFFFD700)),
        ),
        backgroundColor: Colors.grey[900],
        iconTheme: IconThemeData(color: Colors.grey[800]),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.grey[900],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.yellow,
      ),
    );
  }
}
