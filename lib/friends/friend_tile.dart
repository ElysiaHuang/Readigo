import 'dart:io';

import 'package:flutter/material.dart';
import 'package:testapp3/chat/chat_page.dart';
import 'package:testapp3/design_wrapper.dart';
import 'package:testapp3/profile/profile.dart';
import 'package:testapp3/util/constants.dart';
import 'package:testapp3/util/profile_avatar_options.dart';

class FriendTile extends StatelessWidget {
  final String profilePic;
  final String username;
  final String friendCode;
  final String info;
  final bool chat;
  const FriendTile({
    super.key,
    required this.profilePic,
    required this.info,
    required this.friendCode,
    required this.username,
    this.chat = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (chat) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatPage(friendCode: friendCode)),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => DesignWrapper(
                    wrappedWidget: ProfileScreen(friendCode: friendCode),
                  ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Constants.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Constants.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage:
                  profilePic.startsWith('assets/')
                      ? AssetImage(resolvedProfileAvatar(profilePic))
                      : profilePic.startsWith('http')
                      ? NetworkImage(profilePic)
                      : File(profilePic).existsSync()
                      ? FileImage(File(profilePic))
                      : const AssetImage(defaultProfileAvatar) as ImageProvider,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Constants.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    friendCode,
                    style: const TextStyle(
                      color: Constants.mutedInk,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    info,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Constants.mutedInk,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Constants.mutedInk,
            ),
          ],
        ),
      ),
    );
  }
}
