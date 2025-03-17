import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:deeptalk/screens/chat_detail_screen.dart';
import 'package:deeptalk/screens/new_chat_screen.dart';

class ChatsListScreen extends StatefulWidget {
  final String currentUserId;

  const ChatsListScreen({Key? key, required this.currentUserId}) : super(key: key);

  @override
  _ChatsListScreenState createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  String _searchQuery = ""; // Suchtext

  @override
  Widget build(BuildContext context) {
    // Dynamische Farben basierend auf dem aktuellen Modus
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final headerFooterColor = isDarkMode ? Colors.grey[850]! : Colors.grey[100]!;
    final searchBarColor = isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subtitleColor = isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: headerFooterColor,
        elevation: 0,
        title: Text(
          'Chats',
          style: TextStyle(color: textColor, fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: textColor),
            onPressed: () {
              // Mehr-Optionen
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.green),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NewChatScreen(
                    currentUserId: widget.currentUserId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Suchleiste
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: searchBarColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query.toLowerCase();
                  });
                },
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Suchen...',
                  hintStyle: TextStyle(color: subtitleColor),
                  prefixIcon: Icon(Icons.search, color: subtitleColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          // Filteroptionen (Alle, Ungelesen, Favoriten, Gruppen)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterButton('Alle', textColor, searchBarColor),
                _buildFilterButton('Ungelesen', textColor, searchBarColor),
                _buildFilterButton('Favoriten', textColor, searchBarColor),
                _buildFilterButton('Gruppen', textColor, searchBarColor),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(seconds: 1));
              },
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .where('participants', arrayContains: widget.currentUserId)
                    .orderBy('lastMessageTime', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Fehler: ${snapshot.error}',
                        style: TextStyle(color: textColor),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'Keine Chats vorhanden.',
                        style: TextStyle(color: textColor),
                      ),
                    );
                  }

                  final chats = snapshot.data!.docs;

                  final userIds = chats
                      .map((chat) => (chat['participants'] as List<dynamic>)
                      .firstWhere((id) => id != widget.currentUserId))
                      .cast<String>()
                      .toSet()
                      .toList();

                  return FutureBuilder<Map<String, Map<String, dynamic>>>(
                    future: _fetchUserDetails(userIds),
                    builder: (context, userDetailsSnapshot) {
                      if (!userDetailsSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final userDetails = userDetailsSnapshot.data!;

                      final filteredChats = chats.where((chat) {
                        final otherUserId = (chat['participants'] as List)
                            .firstWhere((id) => id != widget.currentUserId);
                        final userData = userDetails[otherUserId] ?? {};
                        final username =
                        (userData['username'] ?? 'Unbekannt').toLowerCase();

                        return username.contains(_searchQuery);
                      }).toList();

                      return ListView.builder(
                        itemCount: filteredChats.length,
                        itemBuilder: (context, index) {
                          final chat = filteredChats[index];
                          return _buildChatItem(
                              context, chat, userDetails, textColor, subtitleColor);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String text, Color textColor, Color buttonColor) {
    return GestureDetector(
      onTap: () {
        // Filterlogik hinzufügen
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(color: textColor, fontSize: 14),
        ),
      ),
    );
  }

  Future<Map<String, Map<String, dynamic>>> _fetchUserDetails(
      List<String> userIds) async {
    final userDetails = <String, Map<String, dynamic>>{};
    for (var userId in userIds) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        userDetails[userId] = userDoc.data() as Map<String, dynamic>;
      }
    }
    return userDetails;
  }

  Widget _buildChatItem(BuildContext context, QueryDocumentSnapshot chat,
      Map<String, Map<String, dynamic>> userDetails, Color textColor, Color subtitleColor) {
    final participants = chat['participants'] as List;
    final otherUserId =
    participants.firstWhere((id) => id != widget.currentUserId);

    final userData = userDetails[otherUserId] ?? {};
    final profilePicture = userData['profilePicture'] ?? '';
    final name = userData['username'] ?? 'Unbekannt';

    final chatData = chat.data() as Map<String, dynamic>;
    final lastMessage = chatData['lastMessage'] ?? 'Keine Nachricht';
    final lastMessageTime =
    (chatData['lastMessageTime'] as Timestamp?)?.toDate();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 25,
          backgroundImage: profilePicture.isNotEmpty
              ? NetworkImage(profilePicture)
              : null,
          child: profilePicture.isEmpty
              ? Icon(Icons.person, color: textColor)
              : null,
        ),
        title: Text(
          name,
          style: TextStyle(color: textColor, fontSize: 16),
        ),
        subtitle: Text(
          lastMessage,
          style: TextStyle(color: subtitleColor, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: lastMessageTime != null
            ? Text(
          DateFormat('HH:mm').format(lastMessageTime),
          style: TextStyle(color: subtitleColor, fontSize: 12),
        )
            : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                chatId: chat.id,
                currentUserId: widget.currentUserId,
                otherUserId: otherUserId,
              ),
            ),
          );
        },
      ),
    );
  }
}
