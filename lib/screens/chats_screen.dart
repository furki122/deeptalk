import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String userId; // Benutzer-ID des Chat-Partners

  const ChatScreen({Key? key, required this.chatId, required this.userId}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  String? userName;
  String? userProfileImage;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _markMessagesAsRead();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userSnapshot.exists) {
        setState(() {
          userName = userSnapshot.data()?['name'];
          userProfileImage = userSnapshot.data()?['profileImage'];
        });
      }
    } catch (e) {
      debugPrint('Fehler beim Abrufen der Benutzerdaten: $e');
    }
  }

  Future<void> _initializeChat() async {
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

    final chatSnapshot = await chatRef.get();
    if (!chatSnapshot.exists) {
      await chatRef.set({
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'participants': [
          FirebaseAuth.instance.currentUser?.uid ?? '',
          widget.userId,
        ],
      });

      await chatRef.collection('messages').add({
        'message': 'Willkommen im Chat!',
        'senderId': 'system',
        'receiverId': FirebaseAuth.instance.currentUser?.uid ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': true,
      });
    }
  }

  Future<void> _sendMessage() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null || _messageController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final timestamp = DateTime.now();

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'message': _messageController.text.trim(),
        'senderId': currentUser.uid,
        'receiverId': widget.userId,
        'timestamp': timestamp,
        'isRead': false,
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'lastMessage': _messageController.text.trim(),
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
    } catch (e) {
      debugPrint('Fehler beim Senden der Nachricht: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nachricht konnte nicht gesendet werden.')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _markMessagesAsRead() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    try {
      final messages = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (var message in messages.docs) {
        await message.reference.update({'isRead': true});
      }
    } catch (e) {
      debugPrint('Fehler beim Markieren der Nachrichten als gelesen: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: userProfileImage != null
            ? CircleAvatar(
          backgroundImage: NetworkImage(userProfileImage!),
        )
            : const CircleAvatar(
          child: Icon(Icons.person),
        ),
        title: Text(userName ?? 'Lädt...'),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              // Anruf-Logik hier hinzufügen
              debugPrint('Anruf gestartet.');
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              // Videoanruf-Logik hier hinzufügen
              debugPrint('Videoanruf gestartet.');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Keine Nachrichten.'));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData =
                    messages[index].data() as Map<String, dynamic>;
                    final isCurrentUser =
                        messageData['senderId'] ==
                            FirebaseAuth.instance.currentUser?.uid;

                    return Align(
                      alignment: isCurrentUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? Colors.blue[300]
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          messageData['message'] ?? '',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Nachricht eingeben...',
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () {
                    // Logik zum Senden von Fotos hinzufügen
                    debugPrint('Kamera geöffnet.');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isSending || _messageController.text.trim().isEmpty
                      ? null
                      : _sendMessage,
                  color: _isSending || _messageController.text.trim().isEmpty
                      ? Colors.grey
                      : Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
