import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_avatar_options.dart';
import 'reading_progress.dart';
import 'service_exception.dart';

/// All writes are authenticated client writes, enforced by firestore.rules.
/// The UID is captured per operation so sign-out cannot redirect an in-flight write.
class FirestoreService {
  final FirebaseFirestore db;
  final String uid;
  FirestoreService(this.db, this.uid);
  DocumentReference<Map<String, dynamic>> get account =>
      db.collection('accounts').doc(uid);
  DocumentReference<Map<String, dynamic>> user(String code) =>
      db.collection('users').doc(code);
  DocumentReference<Map<String, dynamic>> profile(String code) =>
      db.collection('publicProfiles').doc(code);

  static String text(dynamic value, String label, int max, {int min = 0}) {
    if (value is! String ||
        value.trim().length < min ||
        value.trim().length > max) {
      throw ServiceException(
        'Please enter a valid $label ($min–$max characters).',
      );
    }
    return value.trim();
  }

  static void checkCode(String code) {
    if (!RegExp(r'^[A-Z2-9]{5,12}$').hasMatch(code)) {
      throw const ServiceException('Invalid friend code.');
    }
  }

  static Map<String, dynamic> activeData(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null || data['deleting'] == true) {
      throw const ServiceException(
        'Account unavailable. Please sign in again.',
      );
    }
    return data;
  }

  Future<String> ownCode() async {
    final mapping = (await account.get()).data();
    if (mapping == null) {
      throw const ServiceException('Finish setting up your account first.');
    }
    return mapping['friendCode'] as String;
  }

  Future<String> provision(String username, String email, String avatar) async {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    for (var attempt = 0; attempt < 5; attempt++) {
      final code =
          List.generate(
            12,
            (_) => alphabet[random.nextInt(alphabet.length)],
          ).join();
      final result = await db.runTransaction<String?>((tx) async {
        final mapping = await tx.get(account);
        if (mapping.exists) return mapping.data()!['friendCode'] as String;
        // Public profiles also reserve codes permanently after account deletion.
        if ((await tx.get(profile(code))).exists) return null;
        final now = DateTime.now().toUtc();
        final data = <String, dynamic>{
          'ownerUid': uid,
          'email': email,
          'username': username,
          'username_lower': username.toLowerCase(),
          'friendCode': code,
          'bio': 'Welcome to my profile!',
          'profilePic': avatar,
          'dateCreated': FieldValue.serverTimestamp(),
          'level': 1,
          'xp': 0,
          'next_level_xp': 100,
          'books_count': 0,
          'friends': <String>[],
          'blocked': <String>[],
          'streak_count': 0,
          'last_active_date': '',
          'activity_dates': <String>[],
          'daily_quest_date': '',
          'daily_quest_progress': <String, int>{},
          'monthly_quest_month': ReadingProgress.dateKey(now).substring(0, 7),
          'monthly_quest_progress': 0,
          'monthly_badges': <Map<String, dynamic>>[],
          'league_current_index': 0,
          'league_current_week': ReadingProgress.weekKey(now),
          'league_weekly_score': 0,
          'league_history': <Map<String, dynamic>>[],
        };
        tx.set(account, {'friendCode': code});
        tx.set(user(code), data);
        tx.set(profile(code), ReadingProgress.publicProfile(data));
        return code;
      });
      if (result != null) return result;
    }
    throw const ServiceException(
      'Could not reserve a friend code. Please retry.',
    );
  }

  Future<void> updateProfile(String code, Map<String, dynamic> values) async {
    if (values.keys.any(
      (k) => !['username', 'bio', 'profilePic'].contains(k),
    )) {
      throw const ServiceException('Invalid profile fields.');
    }
    final patch = <String, dynamic>{};
    if (values.containsKey('username')) {
      patch['username'] = text(values['username'], 'username', 40, min: 1);
      patch['username_lower'] = (patch['username'] as String).toLowerCase();
    }
    if (values.containsKey('bio')) {
      patch['bio'] = text(values['bio'], 'bio', 500);
    }
    if (values.containsKey('profilePic')) {
      if (!profileAvatarOptions.any(
        (a) => a.assetPath == values['profilePic'],
      )) {
        throw const ServiceException('Choose an available avatar.');
      }
      patch['profilePic'] = values['profilePic'];
    }
    await db.runTransaction((tx) async {
      activeData(await tx.get(user(code)));
      tx.update(user(code), patch);
      tx.update(profile(code), patch);
    });
  }

  Future<Map<String, dynamic>> relationship(
    String other, {
    bool? friend,
    bool? block,
  }) async {
    checkCode(other);
    final code = await ownCode();
    if (code == other) throw const ServiceException('Choose another reader.');
    final members = [code, other]..sort();
    final relation = db.collection('relationships').doc(members.join('_'));
    return db.runTransaction((tx) async {
      final me = activeData(await tx.get(user(code)));
      final them = (await tx.get(profile(other))).data();
      final rel = await tx.get(relation);
      final blocked = List<String>.from(
        rel.data()?['blockedBy'] as List? ?? [],
      );
      final friends = List<String>.from(me['friends'] as List? ?? []);
      final myBlocks = List<String>.from(me['blocked'] as List? ?? []);
      if (them == null || them['deleted'] == true) {
        // Let a reader remove stale references without recreating a conversation.
        if (friend == false || block == false) {
          tx.update(user(code), {
            if (friend == false) 'friends': FieldValue.arrayRemove([other]),
            if (block == false) 'blocked': FieldValue.arrayRemove([other]),
          });
          return {'blockedByMe': false, 'blockedByFriend': false};
        }
        throw const ServiceException('This reader is no longer available.');
      }
      if (friend == true && blocked.isNotEmpty) {
        throw const ServiceException('Unblock this reader before adding them.');
      }
      if (friend != null) {
        if (friend && !friends.contains(other) && friends.length >= 200) {
          throw const ServiceException('Your friends list is full.');
        }
        tx.update(user(code), {
          'friends':
              friend
                  ? FieldValue.arrayUnion([other])
                  : FieldValue.arrayRemove([other]),
        });
      }
      if (block != null) {
        if (block && !myBlocks.contains(other) && myBlocks.length >= 500) {
          throw const ServiceException('Your block list is full.');
        }
        blocked.remove(code);
        if (block) blocked.add(code);
        tx.update(user(code), {
          'blocked':
              block
                  ? FieldValue.arrayUnion([other])
                  : FieldValue.arrayRemove([other]),
          if (block) 'friends': FieldValue.arrayRemove([other]),
        });
      }
      if (!rel.exists || block != null) {
        tx.set(relation, {'members': members, 'blockedBy': blocked});
      }
      return {
        'blockedByMe': blocked.contains(code),
        'blockedByFriend': blocked.contains(other),
      };
    });
  }

  Future<void> saveBook(Map<String, dynamic> values) async {
    final code = await ownCode();
    final book = <String, dynamic>{
      'bookId': text(values['bookId'] ?? '', 'book ID', 100),
      'title': text(values['title'], 'title', 300, min: 1),
      'author': text(values['author'] ?? '', 'author', 300),
      'imageurl': text(values['imageurl'] ?? '', 'cover URL', 2000),
      'review': text(values['review'] ?? '', 'review', 2000),
      'rating': values['rating'],
      'pages': values['pages'] ?? 0,
    };
    if (book['rating'] is! int ||
        book['rating'] < 1 ||
        book['rating'] > 5 ||
        book['pages'] is! int ||
        book['pages'] < 0 ||
        book['pages'] > 100000) {
      throw const ServiceException('Invalid rating or page count.');
    }
    if (!(book['imageurl'] as String).startsWith('https://')) {
      book['imageurl'] = '';
    }
    final books = db.collection('libraries').doc(code).collection('books');
    final ref = books.doc(ReadingProgress.libraryId(book));
    final legacy = books.doc(
      ReadingProgress.libraryId({...book, 'bookId': ''}),
    );
    await db.runTransaction((tx) async {
      final entry = await tx.get(ref), old = await tx.get(legacy);
      final me = activeData(await tx.get(user(code)));
      final consolidate = ref.path != legacy.path && old.exists;
      tx.set(ref, {...book, 'updatedAt': FieldValue.serverTimestamp()});
      if (consolidate) tx.delete(legacy);
      final delta = (entry.exists ? 0 : 1) - (consolidate ? 1 : 0);
      if (delta != 0) {
        final count = max(
          0,
          ReadingProgress.natural(me['books_count']) + delta,
        );
        tx.update(user(code), {'books_count': count});
        tx.update(profile(code), {'books_count': count});
      }
    });
  }

  Future<String> saveQuiz(Map<String, dynamic> quiz) async {
    final code = await ownCode();
    final ref = db.collection('quizAttempts').doc();
    await ref.set({
      ...quiz,
      'uid': uid,
      'friendCode': code,
      'createdAt': FieldValue.serverTimestamp(),
      'completed': false,
    });
    return ref.id;
  }

  Future<Map<String, dynamic>> submitQuiz(String id, List<int> answers) async {
    final code = await ownCode();
    await syncLeague(code);
    final ref = db.collection('quizAttempts').doc(id);
    try {
      return await db.runTransaction((tx) async {
        final attempt = (await tx.get(ref)).data();
        final me = activeData(await tx.get(user(code)));
        if (attempt == null || attempt['uid'] != uid) {
          throw const ServiceException('Quiz not found.');
        }
        if (attempt['completed'] == true) {
          return Map<String, dynamic>.from(attempt['result'] as Map);
        }
        final now = DateTime.now().toUtc(),
            week = ReadingProgress.weekKey(DateTime.now());
        if (me['league_current_week'] != week) {
          throw const ServiceException(
            'A new league week started. Please retry.',
          );
        }
        if (now.difference((attempt['createdAt'] as Timestamp).toDate()) >
            const Duration(hours: 24)) {
          throw const ServiceException(
            'This quiz expired. Please start another.',
          );
        }
        final questions =
            (attempt['questions'] as List)
                .map((q) => Map<String, dynamic>.from(q as Map))
                .toList();
        final correct = ReadingProgress.score(questions, answers),
            gained = correct * (attempt['difficulty'] as int);
        final patch = ReadingProgress.rewardState(me, gained, correct, now);
        patch['league_weekly_score'] =
            ReadingProgress.natural(me['league_weekly_score']) + gained;
        final result = <String, dynamic>{
          'correctCount': correct,
          'gainedXp': gained,
          'startXp': me['xp'],
          'startLevel': me['level'],
          'startNextXp': me['next_level_xp'],
          'targetXp': patch['xp'],
          'targetLevel': patch['level'],
          'questions': questions,
          'selectedAnswers': answers,
        };
        tx.update(user(code), patch);
        tx.update(profile(code), ReadingProgress.publicProfile(patch));
        if (gained > 0) {
          tx.set(
            db
                .collection('weeklyScores')
                .doc(week)
                .collection('players')
                .doc(code),
            {
              'friendCode': code,
              'score': patch['league_weekly_score'],
              'leagueIndex': me['league_current_index'],
              'weekStart': Timestamp.fromDate(ReadingProgress.weekStart(now)),
              'weekEnd': Timestamp.fromDate(
                ReadingProgress.weekStart(now).add(const Duration(days: 7)),
              ),
            },
          );
        }
        tx.update(ref, {
          'completed': true,
          'completedAt': FieldValue.serverTimestamp(),
          'result': result,
        });
        return result;
      });
    } on FirebaseException catch (error) {
      // Rules can reject a stale concurrent commit before the SDK notices the
      // transaction conflict. Never write again on this recovery path.
      if (error.code != 'permission-denied' && error.code != 'aborted') rethrow;
      final saved =
          (await ref.get(const GetOptions(source: Source.server))).data();
      if (saved?['uid'] == uid && saved?['completed'] == true) {
        return Map<String, dynamic>.from(saved!['result'] as Map);
      }
      rethrow;
    }
  }

  Future<void> reportUser(String other, String reason) async {
    checkCode(other);
    final code = await ownCode();
    await db.collection('reports').add({
      'reporter': code,
      'reported': other,
      'reason': text(reason, 'reason', 1000, min: 1),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reportQuiz(String id, int index, String reason) async {
    final code = await ownCode();
    final attempt = (await db.collection('quizAttempts').doc(id).get()).data();
    if (attempt == null ||
        attempt['uid'] != uid ||
        index < 0 ||
        index >= (attempt['questions'] as List).length) {
      throw const ServiceException('Question not found.');
    }
    await db.collection('reported_content').doc('${id}_$index').set({
      'reporter': code,
      'reason': text(reason, 'reason', 1000, min: 1),
      'attemptId': id,
      'questionIndex': index,
      'question': attempt['questions'][index],
      'bookId': attempt['bookId'],
      'title': attempt['title'],
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Page through rankings rather than downloading every reader in one request.
  Future<List<Map<String, dynamic>>> _pages(
    Query<Map<String, dynamic>> query,
  ) async {
    final rows = <Map<String, dynamic>>[];
    for (;;) {
      final page = await query.limit(100).get();
      rows.addAll(page.docs.map((s) => s.data()));
      if (page.docs.length < 100) return rows;
      query = query.startAfterDocument(page.docs.last);
    }
  }

  Future<void> syncLeague(String code) async {
    final me = activeData(await user(code).get());
    final week = ReadingProgress.weekKey(DateTime.now());
    final oldWeek = me['league_current_week'] as String? ?? week;
    if (oldWeek.compareTo(week) >= 0) return;
    final index = ReadingProgress.natural(
      me['league_current_index'],
    ).clamp(0, 9);
    final rows = await _pages(
      db
          .collection('weeklyScores')
          .doc(oldWeek)
          .collection('players')
          .where('leagueIndex', isEqualTo: index),
    );
    rows.removeWhere((r) => ReadingProgress.natural(r['score']) == 0);
    rows.sort((a, b) {
      final score = (b['score'] as int).compareTo(a['score'] as int);
      return score != 0
          ? score
          : (a['friendCode'] as String).compareTo(b['friendCode'] as String);
    });
    final position = rows.indexWhere((r) => r['friendCode'] == code),
        rank = position + 1;
    final score = position < 0 ? 0 : rows[position]['score'] as int;
    final next = ReadingProgress.transitionLeague(
      index,
      score,
      rank,
      rows.length,
    );
    await db.runTransaction((tx) async {
      final latest = activeData(await tx.get(user(code)));
      if (latest['league_current_week'] != oldWeek) return;
      final history = List<dynamic>.from(
        latest['league_history'] as List? ?? [],
      );
      if (score > 0) {
        history.insert(0, {
          'weekKey': oldWeek,
          'fromLeagueIndex': index,
          'fromLeagueName': ReadingProgress.leagueNames[index],
          'toLeagueIndex': next,
          'toLeagueName': ReadingProgress.leagueNames[next],
          'rank': rank,
          'score': score,
          'result':
              next > index
                  ? 'promoted'
                  : next < index
                  ? 'demoted'
                  : 'stayed',
        });
      }
      final patch = {
        'league_current_index': next,
        'league_current_week': week,
        'league_weekly_score': 0,
        'league_history': history.take(12).toList(),
      };
      tx.update(user(code), patch);
      tx.update(profile(code), patch);
    });
  }

  Future<List<Map<String, dynamic>>> leaderboard() async {
    final code = await ownCode();
    await syncLeague(code);
    final me = activeData(await user(code).get());
    final rows = await _pages(
      db
          .collection('publicProfiles')
          .where('league_current_week', isEqualTo: me['league_current_week'])
          .where('league_current_index', isEqualTo: me['league_current_index']),
    );
    rows.removeWhere((r) => r['deleted'] == true);
    rows.sort((a, b) {
      final score = ReadingProgress.natural(
        b['league_weekly_score'],
      ).compareTo(ReadingProgress.natural(a['league_weekly_score']));
      return score != 0
          ? score
          : (a['friendCode'] as String).compareTo(b['friendCode'] as String);
    });
    final size =
        rows
            .where((r) => ReadingProgress.natural(r['league_weekly_score']) > 0)
            .length;
    for (var i = 0; i < rows.length; i++) {
      rows[i]['actualRank'] = i < size ? i + 1 : 0;
      rows[i]['leagueSize'] = size;
    }
    final result = rows.take(100).toList();
    if (!result.any((r) => r['friendCode'] == code)) {
      result.add(
        rows.firstWhere(
          (r) => r['friendCode'] == code,
          orElse:
              () => {
                ...ReadingProgress.publicProfile(me),
                'actualRank': 0,
                'leagueSize': size,
              },
        ),
      );
    }
    return result;
  }

  Future<void> _deletePages(Query<Map<String, dynamic>> query) async {
    for (;;) {
      final page = await query.limit(100).get();
      if (page.docs.isEmpty) return;
      final batch = db.batch();
      for (final doc in page.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  /// Retryable while the Auth user exists. Tombstones prevent code reuse.
  Future<void> deleteData(String code) async {
    await account.update({'deleting': true});
    for (;;) {
      final page =
          await db
              .collection('relationships')
              .where('members', arrayContains: code)
              .limit(100)
              .get();
      if (page.docs.isEmpty) break;
      for (final rel in page.docs) {
        await _deletePages(
          db.collection('chat').doc(rel.id).collection('messages'),
        );
        await rel.reference.delete();
      }
    }
    await _deletePages(
      db.collection('libraries').doc(code).collection('books'),
    );
    await _deletePages(
      db.collection('quizAttempts').where('uid', isEqualTo: uid),
    );
    for (final collection in ['reports', 'reported_content']) {
      await _deletePages(
        db.collection(collection).where('reporter', isEqualTo: code),
      );
    }
    await _deletePages(account.collection('usage'));
    final batch = db.batch();
    batch.delete(user(code));
    batch.set(profile(code), {'friendCode': code, 'deleted': true});
    await batch.commit();
  }
}
