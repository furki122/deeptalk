import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Für die Formatierung des Datums

class UserProfileScreen extends StatelessWidget {
  final String userId; // Benutzer-ID, um Daten aus der Datenbank abzurufen

  const UserProfileScreen({super.key, required this.userId});

  Future<Map<String, dynamic>?> _fetchUserData() async {
    try {
      // Abrufen der Benutzerdaten aus Firestore
      final docSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      return docSnapshot.data();
    } catch (e) {
      debugPrint('Fehler beim Abrufen der Benutzerdaten: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Hintergrund auf weiß gesetzt
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Kontaktinfo',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Funktion für "Bearbeiten"
            },
            child: const Text(
              'Bearbeiten',
              style: TextStyle(color: Colors.teal),
            ),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('Fehler beim Laden der Benutzerdaten'),
            );
          }

          final userData = snapshot.data!;
          final Timestamp? statusTimestamp = userData['statusUpdatedAt']; // Datum des Status-Updates
          final String formattedDate = statusTimestamp != null
              ? DateFormat('dd. MMM yyyy').format(statusTimestamp.toDate()) // Datum formatieren
              : 'Unbekannt';

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profilbild und Name/Benutzername
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      // Profilbild
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: userData['profilePicture'] != null
                            ? NetworkImage(userData['profilePicture'])
                            : null,
                        child: userData['profilePicture'] == null
                            ? const Icon(Icons.person, size: 50, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(height: 10),
                      // Name des Benutzers
                      Text(
                        userData['name'] ?? 'Unbekannt', // Name aus der Datenbank
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Benutzername
                      Text(
                        userData['username'] ?? 'Kein Benutzername verfügbar', // Benutzername aus der Datenbank
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // Aktionen: Audio, Video, Suchen
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _actionButton(
                        icon: Icons.call,
                        label: 'Audio',
                        onPressed: () {
                          // Audioanruf-Funktion
                        },
                      ),
                      _actionButton(
                        icon: Icons.videocam,
                        label: 'Video',
                        onPressed: () {
                          // Videoanruf-Funktion
                        },
                      ),
                      _actionButton(
                        icon: Icons.search,
                        label: 'Suchen',
                        onPressed: () {
                          // Suchfunktion
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Status
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.grey),
                      ListTile(
                        leading: const Icon(Icons.info, color: Colors.teal),
                        title: Text(
                          userData['status'] ?? 'Kein Status verfügbar', // Status aus der Datenbank
                          style: const TextStyle(color: Colors.black),
                        ),
                        subtitle: Text(
                          'Zuletzt aktualisiert: $formattedDate', // Datum des Status-Updates
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      const Divider(color: Colors.grey),
                    ],
                  ),
                ),

                // Medien, Links und Doks
                _listTile(
                  icon: Icons.photo,
                  title: 'Medien, Links und Doks',
                  subtitle: '156', // Beispielwert
                  onTap: () {
                    // Medien anzeigen
                  },
                ),

                // Mit Stern markiert
                _listTile(
                  icon: Icons.star,
                  title: 'Mit Stern markiert',
                  subtitle: 'Keine', // Beispielwert
                  onTap: () {
                    // Markierte Nachrichten anzeigen
                  },
                ),

                // Benachrichtigungen
                _listTile(
                  icon: Icons.notifications,
                  title: 'Benachrichtigungen',
                  onTap: () {
                    // Benachrichtigungseinstellungen
                  },
                ),

                // Chatdesign
                _listTile(
                  icon: Icons.palette,
                  title: 'Chatdesign',
                  onTap: () {
                    // Chatdesign ändern
                  },
                ),

                // In Fotos speichern
                _listTile(
                  icon: Icons.save,
                  title: 'In Fotos speichern',
                  subtitle: 'Standard', // Beispielwert
                  onTap: () {
                    // Speicheroptionen
                  },
                ),

                // Selbstlöschende Nachrichten
                _listTile(
                  icon: Icons.timer,
                  title: 'Selbstlöschende Nachrichten',
                  subtitle: 'Aus', // Beispielwert
                  onTap: () {
                    // Selbstlöschende Nachrichten einstellen
                  },
                ),

                // Chat sperren
                SwitchListTile(
                  activeColor: Colors.teal,
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.grey[700],
                  title: const Text(
                    'Chat sperren',
                    style: TextStyle(color: Colors.black),
                  ),
                  subtitle: const Text(
                    'Sperre und blende diesen Chat auf diesem Gerät aus.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  value: false, // Beispielwert (ersetzen mit echtem Status)
                  onChanged: (value) {
                    // Chat sperren/entsperren
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Hilfsfunktion für Aktionen (Audio, Video, Suchen)
  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(15),
            backgroundColor: Colors.grey[200],
          ),
          onPressed: onPressed,
          child: Icon(icon, color: Colors.teal, size: 30),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(color: Colors.black, fontSize: 14),
        ),
      ],
    );
  }

  // Hilfsfunktion für Listenelemente
  Widget _listTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(
        title,
        style: const TextStyle(color: Colors.black),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle,
        style: const TextStyle(color: Colors.grey),
      )
          : null,
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      onTap: onTap,
    );
  }
}
