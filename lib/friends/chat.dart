import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:testapp3/components/page_intro.dart';
import 'package:testapp3/friends/add_friend.dart';
import 'package:testapp3/util/constants.dart';
import 'package:testapp3/util/firebase_utils.dart';

import 'friend_tile.dart';

class ChatFriendPage extends StatefulWidget {
  final String friendCode;

  const ChatFriendPage({super.key, required this.friendCode});

  @override
  State<ChatFriendPage> createState() => _ChatFriendPageState();
}

class _ChatFriendPageState extends State<ChatFriendPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String getChatID(String code) {
    final friendCodes = [widget.friendCode, code]..sort();
    return friendCodes.join("_");
  }

  Future<String> getLastMessage(String chatID) async {
    try {
      final snapshot =
          await _firestore
              .collection("chat")
              .doc(chatID)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data()['text'] ?? "";
      } else {
        return "";
      }
    } catch (_) {
      return 'Conversation unavailable';
    }
  }

  void _openAddFriend() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddFriendPage()),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageIntro(
          title: 'Chats',
          trailing: FilledButton.icon(
            onPressed: _openAddFriend,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Add'),
            style: FilledButton.styleFrom(
              backgroundColor: Constants.sky,
              foregroundColor: Constants.ink,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: FutureBuilder(
            future: FirebaseUtils.getUserFriends(widget.friendCode),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: TextButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Could not load friends. Tap to retry.'),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState();
              }
              final userFriends = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 18),
                itemCount: userFriends.length,
                itemBuilder: (context, index) {
                  final friendCode = userFriends[index];
                  return FutureBuilder(
                    future: FirebaseUtils.getUserData(friendCode),
                    builder: (context, asyncSnapshot) {
                      if (asyncSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (asyncSnapshot.hasError || !asyncSnapshot.hasData) {
                        return const ListTile(
                          title: Text('Reader unavailable'),
                          subtitle: Text('This account may have been deleted.'),
                        );
                      }
                      final friend = asyncSnapshot.data!;
                      return FutureBuilder(
                        future: getLastMessage(getChatID(friend["friendCode"])),
                        builder: (context, messageSnapshot) {
                          if (messageSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final message = messageSnapshot.data ?? "";

                          return FriendTile(
                            profilePic: friend["profilePic"],
                            info: message.isEmpty ? "No messages yet" : message,
                            chat: true,
                            friendCode: friend["friendCode"],
                            username: friend["username"],
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Constants.border),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 42,
              color: Constants.mutedInk,
            ),
            SizedBox(height: 12),
            Text(
              'No chats yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Constants.ink,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your conversations will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Constants.mutedInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
