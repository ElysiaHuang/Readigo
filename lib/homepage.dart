import 'dart:async';
import 'package:provider/provider.dart';
import 'books/book_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:testapp3/books/bookscreen.dart';
import 'package:testapp3/components/reading_cat.dart';
import 'package:testapp3/friends/chat.dart';
import 'package:testapp3/friends/friends.dart';
import 'package:testapp3/leaderboard/leaderboard.dart';
import 'package:testapp3/landing.dart';
import 'package:testapp3/profile/profile.dart';
import 'package:testapp3/quiz/generate_quiz.dart';
import 'package:testapp3/util/constants.dart';
import 'package:testapp3/util/firebase_utils.dart';

class HomePage extends StatefulWidget {
  final int initialpage;
  final bool selectBookForQuiz;

  const HomePage({
    super.key,
    required this.initialpage,
    this.selectBookForQuiz = false,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  List<Widget> pages = [];
  String? _loadError;
  String? _sessionCode;
  late int selectedpage = widget.initialpage;

  Future<void> _setStatus(bool online) async {
    final code = _sessionCode;
    if (code == null) return;
    try {
      await FirebaseUtils.setOnlineStatus(code, online);
    } catch (_) {
      /* Presence must not block navigation. */
    }
  }

  void onItemTap(int index) {
    if ((index == 0 || index == 1 || index == 3 || index == 4 || index == 5) &&
        FirebaseAuth.instance.currentUser == null) {
      showLoginAlert();
      return;
    }
    setState(() {
      selectedpage = index;
    });
  }

  Future<void> loadPages() async {
    if (mounted) setState(() => _loadError = null);
    try {
      await FirebaseUtils.resumePendingDeletion();
      var friendCode = await FirebaseUtils.getCurrentUserFriendCode();
      if (friendCode == null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;
        await FirebaseUtils.adduser(
          FirebaseUtils.registrationName ?? user.displayName,
          user.email ?? '',
          profilePic: FirebaseUtils.registrationAvatar,
        );
        friendCode = await FirebaseUtils.getCurrentUserFriendCode();
      }
      if (friendCode == null) {
        throw Exception('Account setup is incomplete. Please retry.');
      }
      if (!mounted) return;
      _sessionCode = friendCode;
      setState(() {
        pages = [
          const QuestsPage(),
          FriendsPage(friendCode: friendCode!),
          BookScreen(selectBookForQuiz: widget.selectBookForQuiz),
          ChatFriendPage(friendCode: friendCode),
          ProfileScreen(friendCode: friendCode),
          LeaderboardScreen(friendCode: friendCode),
        ];
      });
      unawaited(_setStatus(true));
    } catch (error) {
      if (mounted) setState(() => _loadError = error.toString());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _setStatus(false);
    }
  }

  // Show alert dialog to LOGIN if friend code is null
  void showLoginAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Login Required"),
          content: Text("Please log in to access this feature."),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            // go to start page
            TextButton(
              child: Text("Login"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LandingPage()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadPages();
  }

  @override
  void dispose() {
    _setStatus(false);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 68,
        centerTitle: false,
        elevation: 0,
        backgroundColor: Constants.appBar,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 18,
        title: const Row(
          children: [
            ReadingCat(size: 40, semanticLabel: 'Bookfania reading companion'),
            SizedBox(width: 10),
            Text(
              'BOOKFANIA',
              style: TextStyle(
                fontSize: 18,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
                color: Constants.ink,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: Constants.ink),
              style: IconButton.styleFrom(
                side: const BorderSide(color: Constants.outline, width: 1.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                unawaited(_setStatus(false));
                context.read<BookProvider>().clearBook();
                FirebaseUtils.clearSession();
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LandingPage()),
                  (_) => false,
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          (pages.isEmpty)
              ? null
              : Container(
                decoration: const BoxDecoration(
                  color: Constants.navSurface,
                  border: Border(
                    top: BorderSide(color: Constants.outline, width: 1.2),
                  ),
                ),
                child: BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Constants.navSurface,
                  selectedItemColor: Constants.ink,
                  unselectedItemColor: Constants.mutedInk,
                  elevation: 0,
                  selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  unselectedLabelStyle: const TextStyle(fontSize: 12),
                  currentIndex: selectedpage,
                  onTap: onItemTap,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.task_alt_rounded),
                      label: "Quests",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.people_alt_outlined),
                      label: "Friends",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.menu_book),
                      label: "Books",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.chat),
                      label: "Chat",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person),
                      label: "Profile",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.emoji_events_outlined),
                      label: "Leagues",
                    ),
                  ],
                ),
              ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Constants.butter, Constants.surfaceAlt],
          ),
        ),
        child:
            (pages.isEmpty)
                ? Center(
                  child:
                      _loadError == null
                          ? const CircularProgressIndicator()
                          : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  _loadError!,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              TextButton(
                                onPressed: loadPages,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                )
                : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Padding(
                    key: ValueKey(selectedpage),
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                    child: pages[selectedpage],
                  ),
                ),
      ),
    );
  }
}
