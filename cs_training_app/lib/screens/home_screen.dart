import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  String _nombre = 'Cargando...';
  String _oposicion = 'Cargando...';
  String _role = 'Cargando...';

  static List<Widget> _widgetOptions = <Widget>[
    const Center(child: Text("Home")),
    ProfileScreen(),
    SettingsScreen(),
  ];

  // Función para cargar los datos de SharedPreferences
  _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombre = prefs.getString('nombre') ?? "Desconocido";
      _oposicion = prefs.getString('oposicion') ?? "No definida";
      _role = prefs.getString('role') ?? "Usuario";
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
    _loadUserData(); // Cargar los datos cuando se inicialice el widget
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home Screen"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Mostrar los datos del usuario en la pantalla
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nombre: $_nombre', style: TextStyle(fontSize: 18)),
                Text('Oposición: $_oposicion', style: TextStyle(fontSize: 18)),
                Text('Role: $_role', style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
          // Mostrar la vista seleccionada
          Expanded(child: _widgetOptions.elementAt(_selectedIndex)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
