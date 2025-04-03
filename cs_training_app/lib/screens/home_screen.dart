import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user/profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _role = "OPOSITOR";

  static List<Widget> _opositorScreens = <Widget>[
    const Center(child: Text("Pantalla de Opositor")),
    ProfileScreen(),
    SettingsScreen(),
  ];

  static List<Widget> _adminScreens = <Widget>[
    const Center(child: Text("Pantalla de Administrador")),
    ProfileScreen(),
    SettingsScreen(),
  ];

  static List<Widget> _profesorScreens = <Widget>[
    const Center(child: Text("Pantalla de Profesor")),
    ProfileScreen(),
    SettingsScreen(),
  ];

  _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('role') ?? "OPOSITOR";
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    List<BottomNavigationBarItem> _bottomNavItems;
    List<Widget> _screens;
    String _appBarTitle = "Home";

    // Ajustamos las pantallas y el título según el rol
    if (_role == "ADMIN") {
      _bottomNavItems = [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
        BottomNavigationBarItem(icon: Icon(Icons.manage_accounts), label: "Gestionar"),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Ajustes"),
      ];
      _screens = _adminScreens;
      _appBarTitle = _selectedIndex == 0
          ? "Inicio"
          : _selectedIndex == 1
          ? "Gestionar"
          : "Ajustes";
    } else if (_role == "PROFESOR") {
      _bottomNavItems = [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
        BottomNavigationBarItem(icon: Icon(Icons.school), label: "Clases"),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Ajustes"),
      ];
      _screens = _profesorScreens;
      _appBarTitle = _selectedIndex == 0
          ? "Inicio"
          : _selectedIndex == 1
          ? "Clases"
          : "Ajustes";
    } else {
      _bottomNavItems = [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
        BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: "Perfil"),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Ajustes"),
      ];
      _screens = _opositorScreens;
      _appBarTitle = _selectedIndex == 0
          ? "Inicio"
          : _selectedIndex == 1
          ? "Perfil"
          : "Ajustes";
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
        items: _bottomNavItems,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.grey[900],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.yellow,
      ),
    );
  }

}
