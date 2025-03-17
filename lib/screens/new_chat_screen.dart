import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_detail_screen.dart';

class NewChatScreen extends StatelessWidget {
  final String currentUserId;

  NewChatScreen({required this.currentUserId});

  Future<void> _startNewChat(BuildContext context, String otherUserId) async {
    final chatRef = FirebaseFirestore.instance.collection('chats');

    QueryDocumentSnapshot<Map<String, dynamic>>? existingChat;

    try {
      existingChat = await chatRef
          .where('participants', arrayContains: currentUserId)
          .get()
          .then((snapshot) => snapshot.docs.firstWhere(
            (doc) => (doc['participants'] as List).contains(otherUserId),
      ));
    } catch (e) {
      // Kein existierender Chat gefunden
      existingChat = null;
    }

    String chatId;

    if (existingChat != null) {
      // Chat existiert bereits
      chatId = existingChat.id;
    } else {
      // Neuen Chat erstellen
      final newChat = await chatRef.add({
        'participants': [currentUserId, otherUserId],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
      chatId = newChat.id;
    }

    // Zum Chat-Detail-Bildschirm navigieren
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          chatId: chatId,
          currentUserId: currentUserId,
          otherUserId: otherUserId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neuen Chat starten'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Ein Fehler ist aufgetreten.'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Keine Benutzer gefunden.'),
            );
          }

          // Filtere den aktuellen Benutzer aus der Liste
          final users = snapshot.data!.docs.where((doc) => doc.id != currentUserId);

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users.elementAt(index);
              final userData = user.data() as Map<String, dynamic>;

              final profilePicture = userData['profilePicture'] ?? '';
              final username = userData['username'] ?? 'Unbekannt';

              return ListTile(
                leading: CircleAvatar(
                  radius: 20, // Kleinere Profilbilder
                  backgroundImage: profilePicture.isNotEmpty
                      ? NetworkImage(profilePicture)
                      : null,
                  child: profilePicture.isEmpty ? const Icon(Icons.person) : null,
                ),
                title: Text(
                  username,
                  style: const TextStyle(fontSize: 16),
                ),
                onTap: () => _startNewChat(context, user.id),
              );
            },
          );
        },
      ),
    );
  }
}
