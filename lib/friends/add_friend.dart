import 'package:flutter/material.dart';
import 'package:testapp3/friends/friend_tile.dart';
import 'package:testapp3/util/constants.dart';

import '../util/firebase_utils.dart';

class AddFriendPage extends StatefulWidget {
  const AddFriendPage({super.key});

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final friendSearchController = TextEditingController();

  List<Map<String, dynamic>> friendList = [];
  String listMessage = "Type a friend code or username to start searching.";
  bool _isSearching = false;
  bool _hasSearched = false;

  Future<void> searchFriend() async {
    if (_isSearching) return;
    final friendSearch = friendSearchController.text.trim();

    if (friendSearch.isEmpty) {
      setState(() {
        friendList.clear();
        listMessage = "Type a friend code or username to start searching.";
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final user =
          RegExp(r'^[A-Z2-9]{5,12}$').hasMatch(friendSearch.toUpperCase())
              ? await FirebaseUtils.getUserData(friendSearch.toUpperCase())
              : null;
      if (user == null) {
        final users = await FirebaseUtils.searchUserByUsername(friendSearch);
        if (users != null && users.isNotEmpty) {
          friendList = users;
          listMessage = "Tap a profile to open it.";
        } else {
          friendList.clear();
          listMessage = "No readers matched that search.";
        }
      } else {
        friendList = [user];
        listMessage = "Tap a profile to open it.";
      }
    } catch (_) {
      listMessage = 'Search failed. Please retry.';
      friendList = [];
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  void dispose() {
    friendSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Friend'),
        backgroundColor: Constants.appBar,
        foregroundColor: Constants.ink,
      ),
      backgroundColor: Constants.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Constants.butter, Constants.surfaceAlt],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCard(),
                const SizedBox(height: 14),
                _buildSearchCard(),
                const SizedBox(height: 14),
                Text(
                  'Search Results',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Constants.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(child: _buildResults()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Constants.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Constants.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Constants.sky,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              color: Constants.ink,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find your people',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Constants.ink,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Search by friend code or username, then open a profile to connect.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Constants.mutedInk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Constants.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Constants.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Constants.ink,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: friendSearchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => searchFriend(),
            decoration: InputDecoration(
              hintText: 'Friend code or username',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Constants.mutedInk,
              ),
              filled: true,
              fillColor: Constants.surfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Constants.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Constants.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Constants.sky, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSearching ? null : searchFriend,
              icon:
                  _isSearching
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.travel_explore_rounded),
              label: Text(_isSearching ? 'Searching...' : 'Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.sky,
                foregroundColor: Constants.ink,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (friendList.isEmpty) {
      return Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Constants.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Constants.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _hasSearched ? Icons.search_off_rounded : Icons.people_outline,
                size: 42,
                color: Constants.mutedInk,
              ),
              const SizedBox(height: 12),
              Text(
                _hasSearched ? 'No Results Yet' : 'Search for a Reader',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Constants.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                listMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Constants.mutedInk,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 18),
      itemCount: friendList.length,
      itemBuilder: (context, index) {
        final friend = friendList[index];
        return FriendTile(
          profilePic: friend["profilePic"],
          info: "Level ${friend["level"]}",
          friendCode: friend["friendCode"],
          username: friend["username"],
        );
      },
    );
  }
}
