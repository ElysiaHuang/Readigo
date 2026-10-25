import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:testapp3/util/profile_avatar_options.dart';
import 'firestore_service.dart';
import 'service_exception.dart';

class FirebaseUtils {
  static FirestoreService get service {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw const ServiceException('Please sign in first.');
    return FirestoreService(FirebaseFirestore.instance, uid);
  }

  static const Map<String, int> _dailyQuestGoals = {
    'earn_xp': 20,
    'finish_quizzes': 2,
    'correct_answers': 10,
  };
  static const int monthlyQuestGoal = 20;
  static const int _leaguePromotionCount = 5;
  static const int _leagueDemotionCount = 3;
  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const List<String> _leagueNames = [
    'Scribbler (Beginner)',
    'Storyteller',
    'Reader',
    'Novel Enthusiast',
    'Page Turner',
    'Bookworm',
    'Plot Navigator',
    'Literary Champion',
    'Epic Reader',
    'Legendary Librarian',
  ];

  static int _readInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');

  static String _dateKey([DateTime? date]) {
    final current = (date ?? DateTime.now()).toUtc();
    return '${current.year}-${_twoDigits(current.month)}-${_twoDigits(current.day)}';
  }

  static String _monthKey([DateTime? date]) {
    final current = (date ?? DateTime.now()).toUtc();
    return '${current.year}-${_twoDigits(current.month)}';
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) return <String>[];

    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static List<Map<String, dynamic>> _readMapList(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];

    return value
        .whereType<Map>()
        .map(
          (badge) => badge.map((key, value) => MapEntry(key.toString(), value)),
        )
        .toList();
  }

  static List<Map<String, dynamic>> _readBadgeList(dynamic value) {
    return _readMapList(value);
  }

  static Map<String, int> _emptyDailyQuestProgress() {
    return {for (final entry in _dailyQuestGoals.entries) entry.key: 0};
  }

  static Map<String, int> _normalizeDailyQuestProgress(
    dynamic value, {
    required bool useStoredValues,
  }) {
    final normalized = _emptyDailyQuestProgress();
    if (!useStoredValues || value is! Map) {
      return normalized;
    }

    for (final entry in _dailyQuestGoals.entries) {
      normalized[entry.key] = min(
        entry.value,
        max(0, _readInt(value[entry.key])),
      );
    }
    return normalized;
  }

  static int calculateTotalProgress(int level, int xp) {
    final normalizedLevel = level < 1 ? 1 : level;
    final normalizedXp = xp < 0 ? 0 : xp;
    return ((normalizedLevel - 1) * normalizedLevel * 100 ~/ 2) + normalizedXp;
  }

  static String monthName(int month) {
    if (month < 1 || month > 12) return '';
    return _monthNames[month - 1];
  }

  static Map<String, int> get dailyQuestGoals =>
      Map<String, int>.from(_dailyQuestGoals);
  static int get leaguePromotionCount => _leaguePromotionCount;
  static int get leagueDemotionCount => _leagueDemotionCount;
  static int get leagueCount => _leagueNames.length;

  static String leagueNameForIndex(int index) {
    if (_leagueNames.isEmpty) return '';
    if (index <= 0) return _leagueNames.first;
    if (index >= _leagueNames.length) return _leagueNames.last;
    return _leagueNames[index];
  }

  static Map<String, dynamic> buildQuestState(
    Map<String, dynamic>? userData, {
    DateTime? now,
  }) {
    final currentTime = (now ?? DateTime.now()).toUtc();
    final todayKey = _dateKey(currentTime);
    final monthKey = _monthKey(currentTime);
    final storedDailyKey = userData?['daily_quest_date']?.toString() ?? '';
    final storedMonthKey = userData?['monthly_quest_month']?.toString() ?? '';

    final dailyProgress = _normalizeDailyQuestProgress(
      userData?['daily_quest_progress'],
      useStoredValues: storedDailyKey == todayKey,
    );
    final completedDailyQuestCount =
        dailyProgress.entries
            .where((entry) => entry.value >= (_dailyQuestGoals[entry.key] ?? 0))
            .length;

    final badges = _readBadgeList(userData?['monthly_badges']);
    badges.sort(
      (a, b) => (b['monthKey']?.toString() ?? '').compareTo(
        a['monthKey']?.toString() ?? '',
      ),
    );

    return {
      'todayKey': todayKey,
      'monthKey': monthKey,
      'streakCount': activeStreak(userData, now: currentTime),
      'lastActiveDate': userData?['last_active_date']?.toString() ?? '',
      'activityDates': _readStringList(userData?['activity_dates']),
      'dailyQuestDate': storedDailyKey == todayKey ? todayKey : '',
      'dailyQuestProgress': dailyProgress,
      'completedDailyQuestCount': completedDailyQuestCount,
      'monthlyQuestMonth': storedMonthKey == monthKey ? monthKey : '',
      'monthlyQuestProgress':
          storedMonthKey == monthKey
              ? min(
                monthlyQuestGoal,
                max(0, _readInt(userData?['monthly_quest_progress'])),
              )
              : 0,
      'monthlyBadges': badges,
    };
  }

  static int activeStreak(Map<String, dynamic>? data, {DateTime? now}) {
    final current = (now ?? DateTime.now()).toUtc();
    final last = data?['last_active_date']?.toString();
    return last == _dateKey(current) ||
            last == _dateKey(current.subtract(const Duration(days: 1)))
        ? max(0, _readInt(data?['streak_count']))
        : 0;
  }

  static String? registrationName;
  static String? registrationAvatar;
  static String? _cachedUid;
  static String? _cachedCode;
  static void clearSession() {
    _cachedUid = null;
    _cachedCode = null;
    registrationName = null;
    registrationAvatar = null;
  }

  static Future<bool> adduser(
    String? username,
    String email, {
    String? profilePic,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final code = await service.provision(
      username?.trim().isNotEmpty == true
          ? username!.trim().substring(0, min(40, username.trim().length))
          : 'Reader',
      FirebaseAuth.instance.currentUser?.email ?? '',
      profileAvatarOptions.any((a) => a.assetPath == profilePic)
          ? profilePic!
          : defaultProfileAvatar,
    );
    if (uid == null || FirebaseAuth.instance.currentUser?.uid != uid) {
      return false;
    }
    _cachedUid = uid;
    _cachedCode = code;
    return true;
  }

  static Future<String?> getCurrentUserFriendCode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      clearSession();
      return null;
    }
    if (_cachedUid == user.uid && _cachedCode != null) return _cachedCode;
    final snapshot =
        await FirebaseFirestore.instance
            .collection('accounts')
            .doc(user.uid)
            .get();
    if (FirebaseAuth.instance.currentUser?.uid != user.uid) return null;
    _cachedUid = user.uid;
    _cachedCode = snapshot.data()?['friendCode'] as String?;
    return _cachedCode;
  }

  static Future<Map<String, dynamic>?> getUserData(String friendCode) async {
    final own = await getCurrentUserFriendCode();
    final collection = own == friendCode ? 'users' : 'publicProfiles';
    final doc =
        await FirebaseFirestore.instance
            .collection(collection)
            .doc(friendCode)
            .get();
    return doc.data()?['deleted'] == true ? null : doc.data();
  }

  static Stream<Map<String, dynamic>?> watchUserData(String friendCode) async* {
    final own = await getCurrentUserFriendCode();
    yield* FirebaseFirestore.instance
        .collection(own == friendCode ? 'users' : 'publicProfiles')
        .doc(friendCode)
        .snapshots()
        .map((s) => s.data()?['deleted'] == true ? null : s.data());
  }

  static Future<void> setOnlineStatus(String friendCode, bool isOnline) async {
    await FirebaseFirestore.instance
        .collection('publicProfiles')
        .doc(friendCode)
        .update({
          'isOnline': isOnline,
          'lastSeen': FieldValue.serverTimestamp(),
        })
        .timeout(const Duration(seconds: 3));
  }

  static Future<List<dynamic>?> getUserBooks(String friendCode) async {
    if (await getCurrentUserFriendCode() != friendCode) return [];
    final snapshot =
        await FirebaseFirestore.instance
            .collection('libraries')
            .doc(friendCode)
            .collection('books')
            .orderBy('updatedAt', descending: true)
            .limit(50)
            .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  static Future<List<dynamic>?> getUserFriends(String friendCode) async {
    if (await getCurrentUserFriendCode() != friendCode) return [];
    return (await getUserData(friendCode))?['friends'] as List? ?? [];
  }

  static Future<List<Map<String, dynamic>>?> searchUserByUsername(
    String username,
  ) async {
    final lower = username.trim().toLowerCase();
    if (lower.isEmpty) return [];
    final snapshot =
        await FirebaseFirestore.instance
            .collection('publicProfiles')
            .where('username_lower', isGreaterThanOrEqualTo: lower)
            .where('username_lower', isLessThanOrEqualTo: '$lower\uf8ff')
            .limit(30)
            .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  static Future<void> updateUser(
    String friendCode,
    Map<String, dynamic> newData,
  ) async {
    if (await getCurrentUserFriendCode() != friendCode) {
      throw const ServiceException('You can only edit your own profile.');
    }
    await service.updateProfile(friendCode, newData);
  }

  static Future<void> addFriend(
    String currentUserCode,
    String friendCode,
  ) async {
    await service.relationship(friendCode, friend: true);
  }

  static Future<bool> isFriends(
    String currentUserCode,
    String friendCode,
  ) async {
    return (await getUserFriends(currentUserCode))?.contains(friendCode) ??
        false;
  }

  static Future<void> removeFriend(
    String currentUserCode,
    String friendCode,
  ) async {
    await service.relationship(friendCode, friend: false);
  }

  static Future<void> blockUser(
    String currentUserCode,
    String friendCode,
  ) async {
    await service.relationship(friendCode, block: true);
  }

  static Future<void> unblockUser(
    String currentUserCode,
    String friendCode,
  ) async {
    await service.relationship(friendCode, block: false);
  }

  static Future<Map<String, dynamic>> relationship(String otherCode) =>
      service.relationship(otherCode);
  static Future<bool> isBlocked(
    String currentUserCode,
    String otherUserCode,
  ) async {
    final own = await getCurrentUserFriendCode();
    if (currentUserCode == otherUserCode) return false;
    final state = await relationship(
      currentUserCode == own ? otherUserCode : currentUserCode,
    );
    return state[currentUserCode == own ? 'blockedByMe' : 'blockedByFriend'] ==
        true;
  }

  static Future<void> reportUser(
    String reporterCode,
    String reportedCode,
    String reason,
  ) async {
    await service.reportUser(reportedCode, reason);
  }

  static Future<void> syncLeagueSystem() async {
    final client = service;
    await client.syncLeague(await client.ownCode());
  }

  static Stream<List<Map<String, dynamic>>> watchLeaderboardUsers() async* {
    final client = service;
    yield await client.leaderboard();
    yield* Stream.periodic(
      const Duration(seconds: 30),
    ).asyncMap((_) => client.leaderboard());
  }

  static Future<void> deleteUser(String friendCode) async {
    final identity = FirebaseAuth.instance.currentUser;
    if (identity == null) throw const ServiceException('Please sign in first.');
    final client = service;
    if (await client.ownCode() != friendCode) {
      throw const ServiceException('You can only delete your own account.');
    }
    await client.deleteData(friendCode);
    await identity.delete();
    await FirebaseAuth.instance.signOut();
    clearSession();
  }

  static Future<void> resumePendingDeletion() async {
    final client = service;
    final mapping = (await client.account.get()).data();
    if (mapping?['deleting'] == true) {
      try {
        await deleteUser(mapping!['friendCode'] as String);
      } on FirebaseAuthException catch (error) {
        if (error.code == 'requires-recent-login') {
          throw const ServiceException(
            'To finish deleting your account, sign out and sign in again.',
          );
        }
        rethrow;
      }
    }
  }
}
