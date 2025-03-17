import 'package:deeptalk/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import der Screens
import 'screens/email_auth_screen.dart';
import 'screens/register_screen.dart';
import 'screens/chats_list_screen.dart';
import 'screens/status_screen.dart';
import 'screens/calls_screen.dart';
import 'screens/search_user_screen.dart';

// Logger-Instanz
final logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    runApp(const MyApp());
  } catch (e) {
    logger.e("Fehler bei der Firebase-Initialisierung: $e");
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = value;
    });
    await prefs.setBool('darkMode', value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DeepTalk',
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: AuthWrapper(
        toggleDarkMode: _toggleDarkMode,
        isDarkMode: _isDarkMode,
      ),
      routes: {
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}


class AuthWrapper extends StatelessWidget {
  final Function(bool) toggleDarkMode;
  final bool isDarkMode;

  const AuthWrapper({super.key, required this.toggleDarkMode, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          logger.e("Fehler in AuthWrapper: ${snapshot.error}");
          return const Scaffold(
            body: Center(child: Text("Ein Fehler ist aufgetreten.")),
          );
        } else if (snapshot.hasData) {
          final currentUserId = snapshot.data!.uid;
          return MainScreen(
            currentUserId: currentUserId,
            toggleDarkMode: toggleDarkMode,
            isDarkMode: isDarkMode,
          );
        } else {
          return const EmailAuthScreen();
        }
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  final String currentUserId;
  final Function(bool) toggleDarkMode;
  final bool isDarkMode;

  const MainScreen({
    super.key,
    required this.currentUserId,
    required this.toggleDarkMode,
    required this.isDarkMode,
  });

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      ChatsListScreen(currentUserId: widget.currentUserId),
      const StatusScreen(),
      const CallsScreen(),
      const SearchUserScreen(),
      SettingsScreen(
        toggleDarkMode: widget.toggleDarkMode,
        isDarkMode: widget.isDarkMode,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DeepTalk'),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          logger.i("Navigiert zu Index: $index");
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Status',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.call),
            label: 'Anrufe',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Freunde suchen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Einstellungen',
          ),
        ],
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
