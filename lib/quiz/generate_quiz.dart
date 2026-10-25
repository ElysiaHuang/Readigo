import 'package:flutter/material.dart';
import 'package:testapp3/components/page_intro.dart';
import 'package:testapp3/components/quest_dashboard.dart';
import 'package:testapp3/homepage.dart';
import 'package:testapp3/util/constants.dart';
import 'package:testapp3/util/firebase_utils.dart';

class QuestsPage extends StatefulWidget {
  const QuestsPage({super.key});

  @override
  State<QuestsPage> createState() => _QuestsPageState();
}

class _QuestsPageState extends State<QuestsPage> {
  late final Future<String?> _friendCodeFuture;

  @override
  void initState() {
    super.initState();
    _friendCodeFuture = FirebaseUtils.getCurrentUserFriendCode();
  }

  void _openBooks() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage(initialpage: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 18, 8, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageIntro(title: 'Quests'),
          const SizedBox(height: 18),
          FutureBuilder<String?>(
            future: _friendCodeFuture,
            builder: (context, snapshot) {
              final friendCode = snapshot.data;
              if (friendCode == null || friendCode.isEmpty) {
                return const SizedBox.shrink();
              }

              return StreamBuilder<Map<String, dynamic>?>(
                stream: FirebaseUtils.watchUserData(friendCode),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting &&
                      !userSnapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (!userSnapshot.hasData || userSnapshot.data == null) {
                    return const SizedBox.shrink();
                  }

                  return QuestDashboard(userData: userSnapshot.data!);
                },
              );
            },
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Constants.surfaceAlt,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Constants.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Start a Quiz',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Open Books and pick a title.',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.4,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: 180,
                  child: ElevatedButton.icon(
                    onPressed: _openBooks,
                    icon: const Icon(Icons.menu_book_rounded),
                    label: const Text('Open Books'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.sky,
                      foregroundColor: Constants.ink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
