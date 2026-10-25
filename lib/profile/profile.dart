import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:testapp3/books/book_tile.dart';
import 'package:testapp3/chat/chat_page.dart';
import 'package:testapp3/components/xp_bar.dart';
import 'package:testapp3/design_wrapper.dart';
import 'package:testapp3/profile/edit_profile.dart';
import 'package:testapp3/profile/profile_header.dart';

import '../homepage.dart';
import '../books/library_page.dart';
import '../util/constants.dart';
import '../util/firebase_utils.dart';
import '../util/profile_avatar_options.dart';

class ProfileScreen extends StatefulWidget {
  final String friendCode;

  const ProfileScreen({super.key, required this.friendCode});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> _profileFuture;
  late Future<List<dynamic>?> _booksFuture;
  bool isOwnProfile = false;
  bool isFriends = false;
  bool isBlockedByMe = false;
  bool isBlockedByFriend = false;

  String _stringValue(
    Map<String, dynamic> data,
    String key, [
    String fallback = '',
  ]) {
    final value = data[key];
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty || text == 'null' ? fallback : text;
  }

  int _intValue(Map<String, dynamic> data, String key, [int fallback = 0]) {
    final value = data[key];
    if (value is int) return value;
    return int.tryParse('${value ?? fallback}') ?? fallback;
  }

  ImageProvider _profileImageProvider(String imageValue) {
    if (imageValue.isEmpty) {
      return const AssetImage(defaultProfileAvatar);
    }
    if (imageValue.startsWith('assets/')) {
      return AssetImage(resolvedProfileAvatar(imageValue));
    }
    if (imageValue.startsWith('http')) {
      return NetworkImage(imageValue);
    }
    if (File(imageValue).existsSync()) {
      return FileImage(File(imageValue));
    }
    return const AssetImage(defaultProfileAvatar);
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  List<DateTime> _currentWeekDates(DateTime now) {
    final normalized = DateTime.utc(now.year, now.month, now.day);
    final startOfWeek = normalized.subtract(
      Duration(days: normalized.weekday % 7),
    );

    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  Widget _buildStreakCard(Map<String, dynamic> userData) {
    final questState = FirebaseUtils.buildQuestState(userData);
    final streakCount = questState['streakCount'] as int;
    final activityDates = Set<String>.from(
      questState['activityDates'] as List<String>,
    );
    final weekDates = _currentWeekDates(DateTime.now().toUtc());
    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final title = isOwnProfile ? 'Daily Streak' : 'Reading Streak';
    final subtitle =
        streakCount == 0
            ? (isOwnProfile
                ? 'Finish a quiz today to start your streak.'
                : 'No streak yet. A finished quiz will start one.')
            : (isOwnProfile
                ? 'Keep your streak alive with another quiz today.'
                : 'This reader is on a $streakCount day streak.');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Constants.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Constants.border),
        boxShadow: [
          BoxShadow(
            color: Constants.sky.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$streakCount day streak',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Constants.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Constants.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Constants.mutedInk,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.local_fire_department_rounded,
                size: 52,
                color: Constants.sky,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: Constants.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(weekDates.length, (index) {
                final date = weekDates[index];
                final isToday =
                    _dateKey(date) == _dateKey(DateTime.now().toUtc());
                final isActive = activityDates.contains(_dateKey(date));

                return Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dayLabels[index],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isToday ? Constants.ink : Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isActive
                                  ? Constants.sky
                                  : const Color(0xFFE1E1E1),
                          border:
                              isToday
                                  ? Border.all(
                                    color: Constants.butter,
                                    width: 3,
                                  )
                                  : null,
                        ),
                        child:
                            isActive
                                ? const Icon(
                                  Icons.local_fire_department_rounded,
                                  color: Colors.white,
                                  size: 18,
                                )
                                : null,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadActions() async {
    try {
      final current = await FirebaseUtils.getCurrentUserFriendCode();
      if (current == null) return;
      final own = current == widget.friendCode;
      final friends =
          own
              ? false
              : await FirebaseUtils.isFriends(current, widget.friendCode);
      final relationship =
          own
              ? <String, dynamic>{}
              : await FirebaseUtils.relationship(widget.friendCode);
      if (!mounted) return;
      setState(() {
        isOwnProfile = own;
        isFriends = friends;
        isBlockedByMe = relationship['blockedByMe'] == true;
        isBlockedByFriend = relationship['blockedByFriend'] == true;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _runAction(Future<void> Function(String) action) async {
    try {
      final current = await FirebaseUtils.getCurrentUserFriendCode();
      if (current == null) return;
      await action(current);
      await _loadActions();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  void addFriend() => _runAction(
    (current) => FirebaseUtils.addFriend(current, widget.friendCode),
  );
  void removeFriend() => _runAction(
    (current) => FirebaseUtils.removeFriend(current, widget.friendCode),
  );
  void blockFriend() => _runAction(
    (current) => FirebaseUtils.blockUser(current, widget.friendCode),
  );
  void unblockFriend() => _runAction(
    (current) => FirebaseUtils.unblockUser(current, widget.friendCode),
  );
  void reportFriend(String reason) => _runAction(
    (current) => FirebaseUtils.reportUser(current, widget.friendCode, reason),
  );

  void showReportDialog() {
    final TextEditingController reportController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report User'),
          content: TextField(
            controller: reportController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Why are you reporting this user?',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final reason = reportController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a reason.')),
                  );
                  return;
                }
                Navigator.pop(context);
                reportFriend(reason);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void showFriendActions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      backgroundColor: Constants.surface,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Friend Actions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _actionCard(
                    icon: isBlockedByMe ? Icons.lock_open : Icons.block,
                    label: isBlockedByMe ? 'Unblock' : 'Block',
                    color: isBlockedByMe ? Colors.green : Colors.redAccent,
                    onTap: () {
                      Navigator.pop(context);
                      if (isBlockedByMe) {
                        unblockFriend();
                      } else {
                        blockFriend();
                      }
                    },
                  ),
                  _actionCard(
                    icon: Icons.report,
                    label: 'Report',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      showReportDialog();
                    },
                  ),
                  _actionCard(
                    icon: Icons.person_remove,
                    label: 'Remove',
                    color: Colors.black87,
                    onTap: () {
                      Navigator.pop(context);
                      removeFriend();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 95,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withValues(alpha: 0.2),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void getCurrentXpAndLevel() async {}

  @override
  void initState() {
    super.initState();
    _profileFuture = FirebaseUtils.getUserData(widget.friendCode);
    _booksFuture = FirebaseUtils.getUserBooks(widget.friendCode);
    _loadActions();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Constants.background,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Constants.butter, Constants.sky],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Constants.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: FutureBuilder(
                      future: _profileFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text("No results"));
                        }
                        final userData = snapshot.data!;
                        final username = _stringValue(
                          userData,
                          "username",
                          "Reader",
                        );
                        final friendCode = _stringValue(
                          userData,
                          "friendCode",
                          widget.friendCode,
                        );
                        final profilePic = _stringValue(userData, "profilePic");
                        final bookCount = _intValue(userData, "books_count");
                        final level = _intValue(userData, "level");
                        final bio = _stringValue(
                          userData,
                          "bio",
                          "No bio yet.",
                        );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ProfileHeader(
                              username: username,
                              friendCode: friendCode,
                              avatar: _profileImageProvider(profilePic),
                              onCopy: () {
                                Clipboard.setData(
                                  ClipboardData(text: friendCode),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Copied to clipboard!"),
                                  ),
                                );
                              },
                              primaryAction: IconButton(
                                onPressed: () async {
                                  if (isOwnProfile) {
                                    final updated = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => DesignWrapper(
                                              wrappedWidget: EditProfilePage(
                                                userData: userData,
                                                friendCode: friendCode,
                                              ),
                                            ),
                                      ),
                                    );
                                    if (mounted && updated == true) {
                                      setState(() {
                                        _profileFuture =
                                            FirebaseUtils.getUserData(
                                              widget.friendCode,
                                            );
                                        _booksFuture =
                                            FirebaseUtils.getUserBooks(
                                              widget.friendCode,
                                            );
                                      });
                                    }
                                  } else if (isFriends) {
                                    removeFriend();
                                  } else {
                                    addFriend();
                                  }
                                },
                                tooltip:
                                    isOwnProfile
                                        ? 'Edit profile'
                                        : isFriends
                                        ? 'Remove friend'
                                        : 'Add friend',
                                icon: Icon(
                                  (isOwnProfile)
                                      ? Icons.settings
                                      : (isFriends)
                                      ? Icons.person_off
                                      : Icons.person_add,
                                ),
                              ),
                              moreAction:
                                  isOwnProfile
                                      ? null
                                      : Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        child: IconButton(
                                          onPressed: showFriendActions,
                                          icon: const Icon(
                                            Icons.more_vert,
                                            color: Color(0xFF37474F),
                                          ),
                                          tooltip: 'More actions',
                                        ),
                                      ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Books Read',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      Text(
                                        '$bookCount',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Level',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      Text(
                                        '$level',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              bio,
                              style: const TextStyle(fontSize: 15),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  if (isOwnProfile)
                    ElevatedButton.icon(
                      onPressed: () async {
                        final userData = await FirebaseUtils.getUserData(
                          widget.friendCode,
                        );
                        if (!context.mounted) return;
                        if (userData != null) {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => DesignWrapper(
                                    wrappedWidget: EditProfilePage(
                                      userData: userData,
                                      friendCode: widget.friendCode,
                                    ),
                                  ),
                            ),
                          );
                          if (mounted && updated == true) {
                            setState(() {
                              _profileFuture = FirebaseUtils.getUserData(
                                widget.friendCode,
                              );
                              _booksFuture = FirebaseUtils.getUserBooks(
                                widget.friendCode,
                              );
                            });
                          }
                        }
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.surfaceAlt,
                        foregroundColor: Constants.ink,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  if (!isOwnProfile)
                    ElevatedButton(
                      onPressed:
                          isBlockedByFriend
                              ? null
                              : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => ChatPage(
                                          friendCode: widget.friendCode,
                                        ),
                                  ),
                                );
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.sky,
                        foregroundColor: Constants.ink,
                      ),
                      child: const Text('Message'),
                    ),
                  if (!isOwnProfile && isBlockedByFriend)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        'You are blocked by this user. Messaging is disabled.',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  if (!isOwnProfile && isBlockedByMe)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        'You have blocked this user. You can unblock in Friend Actions.',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Constants.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: FutureBuilder(
                        future: _profileFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text("No results"));
                          }
                          final userData = snapshot.data!;
                          final level = _intValue(userData, "level");
                          final xp = _intValue(userData, "xp");
                          final nextLevelXp = _intValue(
                            userData,
                            "next_level_xp",
                            100,
                          );
                          return XPBar(
                            level: level,
                            xp: xp,
                            nextLevelXp: nextLevelXp <= 0 ? 100 : nextLevelXp,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isOwnProfile)
                    FutureBuilder(
                      future: _profileFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data == null) {
                          return const SizedBox.shrink();
                        }

                        return _buildStreakCard(snapshot.data!);
                      },
                    ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      isOwnProfile
                          ? 'Recent Saved Books'
                          : 'Library is private',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isOwnProfile)
                    TextButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) =>
                                    LibraryPage(friendCode: widget.friendCode),
                          ),
                        );
                        if (!mounted) return;
                        setState(() {
                          _profileFuture = FirebaseUtils.getUserData(
                            widget.friendCode,
                          );
                          _booksFuture = FirebaseUtils.getUserBooks(
                            widget.friendCode,
                          );
                        });
                      },
                      child: const Text('View all saved books'),
                    ),
                  if (isOwnProfile)
                    SizedBox(
                      height: 320,
                      child: FutureBuilder(
                        future: _booksFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }
                          final querySnapshot = snapshot.data;
                          if (querySnapshot == null || querySnapshot.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("No books saved so far."),
                                  if (isOwnProfile)
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => HomePage(initialpage: 2),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        "Tap here to add a book!",
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }
                          return ListView.builder(
                            itemCount: querySnapshot.length,
                            itemBuilder: (context, index) {
                              final book = querySnapshot[index];
                              final title = book["title"]?.toString() ?? "";
                              final pages =
                                  book["pages"] is int
                                      ? book["pages"] as int
                                      : int.tryParse('${book["pages"] ?? 0}') ??
                                          0;
                              final rating =
                                  book["rating"] is int
                                      ? book["rating"] as int
                                      : int.tryParse(
                                            '${book["rating"] ?? 0}',
                                          ) ??
                                          0;
                              return BookTile(
                                bookId: book['bookId']?.toString() ?? '',
                                bookImageurl:
                                    book["imageurl"]?.toString() ?? "",
                                title:
                                    title.trim().isNotEmpty
                                        ? title
                                        : "Untitled",
                                author: book["author"]?.toString() ?? "",
                                description: book["review"]?.toString() ?? "",
                                pages: pages,
                                shopurl: "shopurl",
                                genre: '',
                                review: true,
                                rating: rating,
                                reviewText: book["review"]?.toString() ?? "",
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
