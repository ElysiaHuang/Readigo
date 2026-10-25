import 'package:flutter/material.dart';
import 'package:testapp3/components/page_intro.dart';
import 'package:testapp3/friends/add_friend.dart';
import 'package:testapp3/util/constants.dart';
import 'package:testapp3/util/firebase_utils.dart';

import 'friend_tile.dart';

class FriendsPage extends StatefulWidget {
  final String friendCode;

  const FriendsPage({super.key, required this.friendCode});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
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
          title: 'Friends',
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
                return _buildEmptyState(
                  title: 'No friends yet',
                  message: 'Add someone to get started.',
                );
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
                      return FriendTile(
                        profilePic: friend["profilePic"],
                        info: "Level ${friend["level"]}",
                        friendCode: friend["friendCode"],
                        username: friend["username"],
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

  Widget _buildEmptyState({required String title, required String message}) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Constants.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Constants.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.people_outline_rounded,
              size: 42,
              color: Constants.mutedInk,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Constants.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
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
