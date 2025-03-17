import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool) toggleDarkMode;
  final bool isDarkMode;

  const SettingsScreen({
    super.key,
    required this.toggleDarkMode,
    required this.isDarkMode,
  });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  /// Speichert die Dark-Mode-Einstellung in SharedPreferences
  Future<void> _saveDarkModePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    print('Dark Mode gespeichert: $value');
  }

  /// Ruft die Benutzerdaten aus Firestore ab
  Future<Map<String, dynamic>> _fetchUserData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      print("Aktuelle UID: $userId");

      if (userId == null) {
        throw Exception('Kein Benutzer eingeloggt!');
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        print("Dokument für UID $userId existiert nicht in Firestore.");
        throw Exception('Benutzerdaten für UID $userId nicht gefunden');
      }

      final data = userDoc.data();
      if (data == null) {
        throw Exception('Benutzer-Dokument ist leer.');
      }

      // Standardwert setzen, falls `profileImageUrl` fehlt
      data['profileImageUrl'] ??= 'https://example.com/default-profile-image.png';
      print("Benutzerdaten abgerufen: $data");

      return data;
    } catch (e) {
      print('Fehler beim Abrufen der Benutzerdaten: $e');
      throw Exception('Fehler beim Abrufen der Benutzerdaten: ${e.toString()}');
    }
  }



  /// Gibt ein Profilbild zurück (entweder aus dem Netzwerk oder ein Platzhalter)
  ImageProvider<Object> _getProfileImage(String? profileImageUrl) {
    if (profileImageUrl == null || profileImageUrl.isEmpty) {
      // Verwende ein Standardbild, wenn kein Profilbild vorhanden ist
      return const AssetImage('assets/profile_placeholder.png');
    }
    return NetworkImage(profileImageUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Fehler: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // FutureBuilder neu laden
                    },
                    child: const Text('Erneut versuchen'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Keine Daten gefunden'));
          } else {
            final userData = snapshot.data!;
            final profileImageUrl = userData['profileImageUrl'] as String?;
            final name = userData['name']?.toString() ?? 'Unbekannter Name';
            final status =
                userData['status']?.toString() ?? 'Hey there! I am using Flutter';
            final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

            return ListView(
              children: [
                // Profilbereich
                ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: _getProfileImage(profileImageUrl),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    status,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  trailing: GestureDetector(
                    onTap: () {
                      if (userId.isNotEmpty && name.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QRCodeScreen(
                              userId: userId,
                              name: name,
                              profileImageUrl: profileImageUrl,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Fehler: Benutzerdaten unvollständig')),
                        );
                      }
                    },
                    child: const Icon(Icons.qr_code, color: Colors.teal),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EditProfileScreen()),
                    );
                  },
                ),
                const Divider(),

                // Datenschutz
                _buildListTile(
                  icon: Icons.lock,
                  title: 'Datenschutz',
                  onTap: () {
                    // Navigiere zur Datenschutz-Seite
                  },
                ),

                // Chats
                _buildListTile(
                  icon: Icons.chat,
                  title: 'Chats',
                  onTap: () {
                    // Navigiere zur Chats-Einstellungsseite
                  },
                ),

                // Benachrichtigungen
                _buildListTile(
                  icon: Icons.notifications,
                  title: 'Benachrichtigungen',
                  onTap: () {
                    // Navigiere zur Benachrichtigungs-Seite
                  },
                ),

                // Speicher und Daten
                _buildListTile(
                  icon: Icons.storage,
                  title: 'Speicher und Daten',
                  onTap: () {
                    // Navigiere zur Speicher-Seite
                  },
                ),

                const Divider(),

                // Dark Mode Einstellung
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.dark_mode, color: Colors.teal),
                          SizedBox(width: 16),
                          Text(
                            'Dark Mode',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isDarkMode,
                        activeColor: Colors.teal,
                        onChanged: (value) async {
                          setState(() {
                            _isDarkMode = value;
                          });
                          await _saveDarkModePreference(value);
                          widget.toggleDarkMode(value);
                        },
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Hilfe
                _buildListTile(
                  icon: Icons.help,
                  title: 'Hilfe',
                  onTap: () {
                    // Navigiere zur Hilfeseite
                  },
                ),

                // Logout
                _buildListTile(
                  icon: Icons.logout,
                  title: 'Logout',
                  iconColor: Colors.red,
                  onTap: () {
                    _showLogoutDialog(context);
                  },
                ),
              ],
            );
          }
        },
      ),
    );
  }

  /// Hilfsfunktion zum Erstellen von ListTiles
  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = Colors.teal,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      onTap: onTap,
    );
  }

  /// Zeigt den Logout-Dialog an
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abmelden'),
        content: const Text('Möchtest du dich wirklich abmelden?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Abmelden'),
          ),
        ],
      ),
    );
  }
}

class QRCodeScreen extends StatelessWidget {
  final String userId;
  final String? profileImageUrl;
  final String name;

  const QRCodeScreen({
    super.key,
    required this.userId,
    this.profileImageUrl,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR-Code'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () {
              Share.share('Hier ist mein QR-Code:\n\nName: $name\nID: $userId');
            },
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: profileImageUrl != null && (profileImageUrl?.isNotEmpty ?? false)
                  ? NetworkImage(profileImageUrl!)
                  : const AssetImage('assets/profile_placeholder.png'),
            ),
            const SizedBox(height: 8),
            Text(
              name.isNotEmpty ? name : '.',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'DeepTalk-Kontakt',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: userId.isNotEmpty ? userId : 'Ungültige Benutzer-ID',
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Dein QR-Code ist privat. Wenn du ihn mit jemandem teilst, '
                    'kann diese Person ihn mit ihrer Kamera scannen, um dich als Kontakt hinzuzufügen.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Funktion zum Scannen eines QR-Codes
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Scannen'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
