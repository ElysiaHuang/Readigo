import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'service_exception.dart';

/// Progress in the client-only model is self-reported, not an anti-cheat system.
class ReadingProgress {
  static const leagueNames = [
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
  static const goals = {
    'earn_xp': 20,
    'finish_quizzes': 2,
    'correct_answers': 10,
  };
  static int natural(dynamic n) => n is int && n >= 0 ? n : 0;
  static String dateKey(DateTime date) =>
      date.toUtc().toIso8601String().substring(0, 10);
  static DateTime weekStart(DateTime date) {
    final utc = date.toUtc();
    return DateTime.utc(
      utc.year,
      utc.month,
      utc.day,
    ).subtract(Duration(days: utc.weekday - 1));
  }

  static String weekKey(DateTime date) => dateKey(weekStart(date));
  static String libraryId(Map<String, dynamic> book) =>
      sha256
          .convert(
            utf8.encode(
              (book['bookId'] as String? ?? '').isNotEmpty
                  ? book['bookId'] as String
                  : '${book['title'].toString().trim().toLowerCase()}\n${book['author'].toString().trim().toLowerCase()}',
            ),
          )
          .toString();

  static int score(List<Map<String, dynamic>> questions, List<int> answers) {
    if (answers.length != questions.length ||
        answers.any((a) => a < 0 || a > 3)) {
      throw const ServiceException('Answer every question before submitting.');
    }
    return List.generate(
      answers.length,
      (i) => answers[i] == questions[i]['answer'],
    ).where((correct) => correct).length;
  }

  static int transitionLeague(int index, int score, int rank, int size) {
    if (score <= 0) return index;
    if (rank <= 5) return min(9, index + 1);
    if (rank > size - 3) return max(0, index - 1);
    return index;
  }

  static Map<String, dynamic> rewardState(
    Map<String, dynamic> user,
    int gainedXp,
    int correctAnswers,
    DateTime now,
  ) {
    final today = dateKey(now), month = dateKey(now).substring(0, 7);
    final yesterday = dateKey(now.subtract(const Duration(days: 1)));
    var xp = natural(user['xp']) + gainedXp,
        level = max(1, natural(user['level']));
    while (xp >= level * 100) {
      xp -= level * 100;
      level++;
    }
    final prior =
        user['daily_quest_date'] == today
            ? user['daily_quest_progress'] as Map? ?? {}
            : <String, dynamic>{};
    final progress = <String, int>{};
    final increments = {
      'earn_xp': gainedXp,
      'finish_quizzes': 1,
      'correct_answers': correctAnswers,
    };
    var monthly =
        user['monthly_quest_month'] == month
            ? min(20, natural(user['monthly_quest_progress']))
            : 0;
    for (final entry in goals.entries) {
      final before = min(entry.value, natural(prior[entry.key]));
      progress[entry.key] = min(entry.value, before + increments[entry.key]!);
      if (before < entry.value && progress[entry.key] == entry.value) {
        monthly = min(20, monthly + 1);
      }
    }
    final badges = List<Map<String, dynamic>>.from(
      (user['monthly_badges'] as List? ?? []).map(
        (b) => Map<String, dynamic>.from(b as Map),
      ),
    );
    const months = [
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
    if (monthly == 20 && !badges.any((b) => b['monthKey'] == month)) {
      final label = months[now.toUtc().month - 1];
      badges.insert(0, {
        'monthKey': month,
        'title': '$label Quest',
        'monthLabel': label,
        'year': now.toUtc().year,
        'earnedAt': today,
      });
    }
    final dates =
        {
            ...List<String>.from(user['activity_dates'] as List? ?? []),
            today,
          }.toList()
          ..sort();
    return {
      'xp': xp,
      'level': level,
      'next_level_xp': level * 100,
      'streak_count':
          user['last_active_date'] == today
              ? natural(user['streak_count'])
              : user['last_active_date'] == yesterday
              ? natural(user['streak_count']) + 1
              : 1,
      'last_active_date': today,
      'activity_dates': dates.skip(max(0, dates.length - 28)).toList(),
      'daily_quest_date': today,
      'daily_quest_progress': progress,
      'monthly_quest_month': month,
      'monthly_quest_progress': monthly,
      'monthly_badges': badges.take(120).toList(),
    };
  }

  static const publicKeys = [
    'username',
    'username_lower',
    'bio',
    'profilePic',
    'friendCode',
    'level',
    'xp',
    'next_level_xp',
    'books_count',
    'league_current_index',
    'league_current_week',
    'league_weekly_score',
    'league_history',
  ];
  static Map<String, dynamic> publicProfile(Map<String, dynamic> user) => {
    for (final key in publicKeys)
      if (user.containsKey(key)) key: user[key],
  };
}
