import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_profile_screen.dart'; // Importiere den UserProfileScreen

class SearchUserScreen extends StatelessWidget {
  const SearchUserScreen({super.key});

  // Benutzerliste anzeigen
  Future<List<DocumentSnapshot>> _fetchUsers() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('users').get();
      return querySnapshot.docs.where((doc) => doc.id != currentUserId).toList();
    } catch (e) {
      debugPrint('Fehler beim Abrufen der Benutzer: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Benutzer suchen'),
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _fetchUsers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Fehler beim Laden der Benutzer: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final users = snapshot.data!;
          if (users.isEmpty) {
            return const Center(
              child: Text('Keine Benutzer gefunden.'),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: userData['profilePicture'] != null
                        ? NetworkImage(userData['profilePicture'])
                        : null,
                    child: userData['profilePicture'] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(userData['username'] ?? 'Unbekannt'),
                  subtitle: Text(userData['email'] ?? 'Keine E-Mail'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () {
                    // Profilseite öffnen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfileScreen(userId: users[index].id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
