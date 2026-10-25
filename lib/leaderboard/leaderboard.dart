import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:testapp3/design_wrapper.dart';
import 'package:testapp3/profile/profile.dart';
import 'package:testapp3/util/constants.dart';
import 'package:testapp3/util/firebase_utils.dart';
import 'package:testapp3/util/profile_avatar_options.dart';
import 'package:testapp3/util/reading_progress.dart';

class LeaderboardScreen extends StatefulWidget {
  final String friendCode;

  const LeaderboardScreen({super.key, required this.friendCode});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _isSyncing = true;
  String? _syncError;
  Timer? _rivalRefreshTimer;

  @override
  void initState() {
    super.initState();
    _syncLeagueData();
    _rivalRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _rivalRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _syncLeagueData() async {
    try {
      await FirebaseUtils.syncLeagueSystem();
      if (!mounted) return;
      setState(() {
        _isSyncing = false;
        _syncError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSyncing = false;
        _syncError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSyncing) {
      return const Scaffold(
        backgroundColor: Constants.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_syncError != null) {
      return Scaffold(
        backgroundColor: Constants.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 42,
                  color: Constants.primary,
                ),
                const SizedBox(height: 12),
                const Text(
                  'We could not load your league right now.',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Constants.ink,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try again in a moment.',
                  style: const TextStyle(
                    color: Constants.mutedInk,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isSyncing = true;
                      _syncError = null;
                    });
                    _syncLeagueData();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Constants.background,
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirebaseUtils.watchLeaderboardUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Unable to load the leaderboard right now.',
                    style: const TextStyle(
                      color: Constants.mutedInk,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final entries =
                (snapshot.data ?? const <Map<String, dynamic>>[])
                    .map(_LeaderboardEntry.fromMap)
                    .where((entry) => entry.friendCode.isNotEmpty)
                    .toList();

            if (entries.isEmpty) {
              return _buildEmptyState();
            }

            final currentUser = entries.firstWhere(
              (entry) => entry.friendCode == widget.friendCode,
              orElse: () => entries.first,
            );

            final currentLeagueIndex = currentUser.leagueIndex;
            final currentLeague = _leagueDefinitions[currentLeagueIndex];
            final currentLeagueEntries =
                entries
                    .where((entry) => entry.leagueIndex == currentLeagueIndex)
                    .toList()
                  ..sort((a, b) {
                    final scoreCompare = b.weeklyScore.compareTo(a.weeklyScore);
                    if (scoreCompare != 0) {
                      return scoreCompare;
                    }
                    return a.friendCode.compareTo(b.friendCode);
                  });

            final currentRank = currentUser.actualRank;
            final status = _leagueStatusFor(
              rank: currentRank,
              leagueSize: currentUser.leagueSize,
              leagueIndex: currentLeagueIndex,
            );
            final practiceRivals = _practiceRivalsFor();

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroCard(
                          currentUser: currentUser,
                          currentLeague: currentLeague,
                          currentRank: currentRank,
                          leagueSize: currentUser.leagueSize,
                          status: status,
                        ),
                        const SizedBox(height: 18),
                        _buildPracticeRivals(
                          currentUser: currentUser,
                          rivals: practiceRivals,
                        ),
                        const SizedBox(height: 18),
                        _buildLeaguePath(currentLeagueIndex),
                        if (currentUser.leagueHistory.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _buildPastLeagueSection(currentUser.leagueHistory),
                        ],
                        if (currentLeagueEntries.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _buildTopReadersStrip(currentLeagueEntries),
                        ],
                      ],
                    ),
                  ),
                ),
                if (currentLeagueEntries.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                      child: _buildLeagueEmptyState(currentLeague),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                    sliver: SliverList.separated(
                      itemCount: currentLeagueEntries.length,
                      separatorBuilder:
                          (context, index) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final entry = currentLeagueEntries[index];
                        return _buildLeaderboardTile(
                          context: context,
                          entry: entry,
                          rank: entry.actualRank,
                          isCurrentUser: entry.friendCode == widget.friendCode,
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroCard({
    required _LeaderboardEntry currentUser,
    required _LeagueDefinition currentLeague,
    required int currentRank,
    required int leagueSize,
    required _LeagueStatus status,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: currentLeague.gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: currentLeague.gradient.last.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Constants.surface.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Constants.surface.withValues(alpha: 0.96),
                    width: 1.2,
                  ),
                ),
                child: Icon(currentLeague.icon, color: Constants.ink, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentLeague.name,
                      style: const TextStyle(
                        color: Constants.ink,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This week',
                      style: TextStyle(
                        color: Constants.ink.withValues(alpha: 0.68),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Constants.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _timeUntilReset(),
                  style: const TextStyle(
                    color: Constants.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildStatPill(
                icon: Icons.emoji_events_outlined,
                value: '#$currentRank',
              ),
              _buildStatPill(
                icon: Icons.local_fire_department_outlined,
                value: '${currentUser.weeklyScore}',
              ),
              _buildStatPill(icon: status.icon, value: status.label),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaguePath(int currentLeagueIndex) {
    final currentLeague = _leagueDefinitions[currentLeagueIndex];
    final nextLeague =
        currentLeagueIndex < _leagueDefinitions.length - 1
            ? _leagueDefinitions[currentLeagueIndex + 1]
            : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final currentCard = _buildLeagueStatusCard(
          league: currentLeague,
          isLocked: false,
        );
        final nextCard =
            nextLeague == null
                ? _buildHighestLeagueCard()
                : _buildLeagueStatusCard(league: nextLeague, isLocked: true);

        if (compact) {
          return Column(
            children: [currentCard, const SizedBox(height: 12), nextCard],
          );
        }

        return Row(
          children: [
            Expanded(child: currentCard),
            const SizedBox(width: 12),
            Expanded(child: nextCard),
          ],
        );
      },
    );
  }

  List<_PracticeRival> _practiceRivalsFor() {
    final now = DateTime.now().toUtc();
    final weekStart = ReadingProgress.weekStart(now);
    final elapsedMinutes = math.max(0, now.difference(weekStart).inMinutes);
    final weekSeed =
        weekStart.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;

    return [
      _simulatedRival(
        name: 'Piper Page',
        activity: 'Finished a chapter',
        icon: Icons.auto_stories_rounded,
        color: const Color(0xFFD7A17D),
        weekSeed: weekSeed,
        elapsedMinutes: elapsedMinutes,
        baseScore: 2,
        sessionMinutes: 360,
        minimumPoints: 3,
        pointVariation: 3,
      ),
      _simulatedRival(
        name: 'Moss Margins',
        activity: 'Logged a reading session',
        icon: Icons.edit_note_rounded,
        color: const Color(0xFF8CA98A),
        weekSeed: weekSeed + 17,
        elapsedMinutes: elapsedMinutes,
        baseScore: 1,
        sessionMinutes: 480,
        minimumPoints: 2,
        pointVariation: 3,
      ),
      _simulatedRival(
        name: 'Nova Novel',
        activity: 'Completed a practice quiz',
        icon: Icons.quiz_rounded,
        color: const Color(0xFF9FA8C8),
        weekSeed: weekSeed + 31,
        elapsedMinutes: elapsedMinutes,
        baseScore: 0,
        sessionMinutes: 720,
        minimumPoints: 4,
        pointVariation: 4,
      ),
    ];
  }

  _PracticeRival _simulatedRival({
    required String name,
    required String activity,
    required IconData icon,
    required Color color,
    required int weekSeed,
    required int elapsedMinutes,
    required int baseScore,
    required int sessionMinutes,
    required int minimumPoints,
    required int pointVariation,
  }) {
    final completedSessions = elapsedMinutes ~/ sessionMinutes;
    var score = baseScore;
    for (var session = 1; session <= completedSessions; session++) {
      score += minimumPoints + ((weekSeed + session * 11) % pointVariation);
    }

    final lastActivityMinutes =
        completedSessions == 0
            ? null
            : elapsedMinutes - completedSessions * sessionMinutes;
    final status =
        lastActivityMinutes == null
            ? 'Planning this week’s next session'
            : '$activity ${_relativeTime(lastActivityMinutes)}';
    return _PracticeRival(
      name: name,
      specialty: status,
      icon: icon,
      color: color,
      score: score,
    );
  }

  String _relativeTime(int minutes) {
    if (minutes < 2) return 'just now';
    if (minutes < 60) return '${minutes}m ago';
    final hours = minutes ~/ 60;
    return hours == 1 ? '1h ago' : '${hours}h ago';
  }

  Widget _buildPracticeRivals({
    required _LeaderboardEntry currentUser,
    required List<_PracticeRival> rivals,
  }) {
    final board = [
      ...rivals.map(_RivalBoardEntry.bot),
      _RivalBoardEntry.currentUser(currentUser),
    ]..sort((a, b) => b.score.compareTo(a.score));
    final nearest = rivals.reduce(
      (closest, rival) =>
          (rival.score - currentUser.weeklyScore).abs() <
                  (closest.score - currentUser.weeklyScore).abs()
              ? rival
              : closest,
    );
    final difference = (nearest.score - currentUser.weeklyScore).abs();
    final direction =
        nearest.score > currentUser.weeklyScore ? 'ahead of' : 'behind';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Constants.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Constants.outline, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Constants.cocoa.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Constants.blush,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Constants.outline),
                ),
                child: const Icon(Icons.bolt_rounded, color: Constants.cocoa),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Practice rivals',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Constants.ink,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'They keep their own pace while you’re away.',
                      style: TextStyle(fontSize: 13, color: Constants.mutedInk),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: Constants.surfaceAlt,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Constants.border),
                ),
                child: const Text(
                  'SIMULATED',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w800,
                    color: Constants.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Constants.butter,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Constants.border),
            ),
            child: Text(
              difference == 0
                  ? 'You are tied with ${nearest.name}. One quiz can take the lead.'
                  : '${nearest.name} is $difference points $direction you. Keep reading to close the gap.',
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: Constants.ink,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(board.length, (index) {
            final entry = board[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == board.length - 1 ? 0 : 8,
              ),
              child: _buildRivalRow(entry: entry, rank: index + 1),
            );
          }),
          const SizedBox(height: 10),
          const Text(
            'Practice rivals are local Bookfania bots. Their activity advances from elapsed time, but never affects your live rank, promotion, or rewards.',
            style: TextStyle(
              fontSize: 11,
              height: 1.35,
              color: Constants.mutedInk,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRivalRow({required _RivalBoardEntry entry, required int rank}) {
    final rankColor = _rankColor(rank);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color:
            entry.isCurrentUser ? Constants.surfaceAlt : Constants.navSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: entry.isCurrentUser ? Constants.outline : Constants.border,
          width: entry.isCurrentUser ? 1.2 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '#$rank',
              style: TextStyle(
                color: rankColor,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: entry.color.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(entry.icon, color: entry.color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Constants.ink,
                        ),
                      ),
                    ),
                    if (!entry.isCurrentUser) ...[
                      const SizedBox(width: 6),
                      const Text(
                        'BOT',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w800,
                          color: Constants.mutedInk,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  entry.subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Constants.mutedInk,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${entry.score}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Constants.cocoa,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueStatusCard({
    required _LeagueDefinition league,
    required bool isLocked,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Constants.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLocked ? Constants.border : Constants.accent,
          width: isLocked ? 1 : 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: league.gradient),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isLocked ? Icons.lock_rounded : league.icon,
                  color: Constants.ink,
                  size: 20,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      isLocked
                          ? Constants.surfaceAlt
                          : Constants.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isLocked ? 'Locked' : 'Now',
                  style: TextStyle(
                    color: isLocked ? Constants.mutedInk : Constants.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            league.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildHighestLeagueCard() {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Constants.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Constants.ink,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Top',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildPastLeagueSection(List<_LeagueHistoryEntry> history) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Constants.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Constants.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'History',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...history.take(4).map((entry) => _buildHistoryTile(entry)),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(_LeagueHistoryEntry entry) {
    final resultColor = _historyResultColor(entry.result);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Constants.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: resultColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.history_rounded, color: resultColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.fromLeagueName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_historyResultLabel(entry.result)} • #${entry.rank}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatWeekKey(entry.weekKey),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopReadersStrip(List<_LeaderboardEntry> leagueEntries) {
    final topReaders = leagueEntries.take(3).toList();

    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: topReaders.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final entry = topReaders[index];
          final rank = index + 1;

          return Container(
            width: 158,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Constants.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _rankColor(rank).withValues(alpha: 0.3),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                    CircleAvatar(
                      radius: 22,
                      backgroundImage: _buildProfileImage(entry.profilePic),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _rankColor(rank).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '#$rank',
                        style: TextStyle(
                          color: _rankColor(rank),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  entry.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Constants.surfaceAlt,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${entry.weeklyScore}',
                    style: const TextStyle(
                      color: Constants.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardTile({
    required BuildContext context,
    required _LeaderboardEntry entry,
    required int rank,
    required bool isCurrentUser,
  }) {
    final rankColor = _rankColor(rank);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => DesignWrapper(
                    wrappedWidget: ProfileScreen(friendCode: entry.friendCode),
                  ),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            color: isCurrentUser ? Constants.surfaceAlt : Constants.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  isCurrentUser
                      ? Constants.accent
                      : rank <= 3
                      ? rankColor.withValues(alpha: 0.26)
                      : Colors.transparent,
              width: isCurrentUser || rank <= 3 ? 1.3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: rankColor.withValues(alpha: rank <= 3 ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        color: rankColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 24,
                  backgroundImage: _buildProfileImage(entry.profilePic),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (isCurrentUser)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Constants.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'You',
                                style: TextStyle(
                                  color: Constants.accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${entry.friendCode}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Constants.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${entry.weeklyScore}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: Constants.surfaceAlt,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.emoji_events_outlined,
                color: Constants.ink,
                size: 38,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No league data',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeagueEmptyState(_LeagueDefinition league) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: league.gradient),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(league.icon, color: Constants.ink, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              league.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill({required IconData icon, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Constants.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Constants.surface.withValues(alpha: 0.92)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Constants.ink.withValues(alpha: 0.75), size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Constants.ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider _buildProfileImage(String profilePic) {
    if (profilePic.isEmpty) {
      return const AssetImage(defaultProfileAvatar);
    }

    if (profilePic.startsWith('assets/')) {
      return AssetImage(resolvedProfileAvatar(profilePic));
    }

    if (profilePic.startsWith('http')) {
      return NetworkImage(profilePic);
    }

    if (File(profilePic).existsSync()) {
      return FileImage(File(profilePic));
    }

    return const AssetImage(defaultProfileAvatar);
  }

  _LeagueStatus _leagueStatusFor({
    required int rank,
    required int leagueSize,
    required int leagueIndex,
  }) {
    if (rank > 0 &&
        rank <= FirebaseUtils.leaguePromotionCount &&
        leagueIndex < _leagueDefinitions.length - 1) {
      return const _LeagueStatus(label: 'Top 5', icon: Icons.north_rounded);
    }

    final isDropZone =
        rank > FirebaseUtils.leaguePromotionCount &&
        rank > leagueSize - FirebaseUtils.leagueDemotionCount &&
        leagueIndex > 0;

    if (isDropZone) {
      return const _LeagueStatus(label: 'Drop', icon: Icons.south_rounded);
    }

    return const _LeagueStatus(label: 'Safe', icon: Icons.drag_handle_rounded);
  }

  String _timeUntilReset() {
    final now = DateTime.now().toUtc();
    final startOfWeek = DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - DateTime.monday));
    final nextReset = startOfWeek.add(const Duration(days: 7));
    final remaining = nextReset.difference(now);
    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    if (days > 0) {
      return '$days d $hours h left';
    }
    return '${remaining.inHours} h left';
  }

  String _formatWeekKey(String weekKey) {
    final parts = weekKey.split('-');
    if (parts.length != 3) return weekKey;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return weekKey;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final monthLabel = months[(month.clamp(1, 12)) - 1];
    return 'Week of $monthLabel $day, $year';
  }

  String _historyResultLabel(String result) {
    switch (result) {
      case 'promoted':
        return 'Promoted';
      case 'demoted':
        return 'Dropped down';
      default:
        return 'Stayed put';
    }
  }

  Color _historyResultColor(String result) {
    switch (result) {
      case 'promoted':
        return const Color(0xFF2F9E66);
      case 'demoted':
        return const Color(0xFFE76F51);
      default:
        return const Color(0xFF6C7183);
    }
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFD4A62B);
      case 2:
        return const Color(0xFF6B7A99);
      case 3:
        return const Color(0xFFB8744A);
      default:
        return Constants.primary;
    }
  }
}

class _LeaderboardEntry {
  final String friendCode;
  final String username;
  final String profilePic;
  final int leagueIndex;
  final int weeklyScore;
  final int booksRead;
  final int actualRank;
  final int leagueSize;
  final List<_LeagueHistoryEntry> leagueHistory;

  const _LeaderboardEntry({
    required this.friendCode,
    required this.username,
    required this.profilePic,
    required this.leagueIndex,
    required this.weeklyScore,
    required this.booksRead,
    required this.actualRank,
    required this.leagueSize,
    required this.leagueHistory,
  });

  factory _LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    final history = map['league_history'];
    final historyEntries =
        history is List
            ? history
                .whereType<Map>()
                .map(
                  (item) => _LeagueHistoryEntry.fromMap(
                    item.map((key, value) => MapEntry(key.toString(), value)),
                  ),
                )
                .toList()
            : <_LeagueHistoryEntry>[];

    return _LeaderboardEntry(
      friendCode: map['friendCode']?.toString().trim() ?? '',
      username:
          map['username']?.toString().trim().isNotEmpty == true
              ? map['username'].toString()
              : 'Reader',
      profilePic: map['profilePic']?.toString() ?? '',
      leagueIndex: map['league_current_index'] as int? ?? 0,
      weeklyScore: map['league_weekly_score'] as int? ?? 0,
      booksRead: map['books_count'] as int? ?? 0,
      actualRank: map['actualRank'] as int? ?? 0,
      leagueSize: map['leagueSize'] as int? ?? 0,
      leagueHistory: historyEntries,
    );
  }
}

class _LeagueHistoryEntry {
  final String weekKey;
  final String fromLeagueName;
  final int rank;
  final int score;
  final String result;

  const _LeagueHistoryEntry({
    required this.weekKey,
    required this.fromLeagueName,
    required this.rank,
    required this.score,
    required this.result,
  });

  factory _LeagueHistoryEntry.fromMap(Map<String, dynamic> map) {
    return _LeagueHistoryEntry(
      weekKey: map['weekKey']?.toString() ?? '',
      fromLeagueName: map['fromLeagueName']?.toString() ?? 'League',
      rank: map['rank'] as int? ?? 0,
      score: map['score'] as int? ?? 0,
      result: map['result']?.toString() ?? 'stayed',
    );
  }
}

class _LeagueDefinition {
  final String name;
  final String shortName;
  final IconData icon;
  final List<Color> gradient;

  const _LeagueDefinition({
    required this.name,
    required this.shortName,
    required this.icon,
    required this.gradient,
  });
}

class _LeagueStatus {
  final String label;
  final IconData icon;

  const _LeagueStatus({required this.label, required this.icon});
}

class _PracticeRival {
  final String name;
  final String specialty;
  final IconData icon;
  final Color color;
  final int score;

  const _PracticeRival({
    required this.name,
    required this.specialty,
    required this.icon,
    required this.color,
    required this.score,
  });
}

class _RivalBoardEntry {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int score;
  final bool isCurrentUser;

  const _RivalBoardEntry({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.score,
    required this.isCurrentUser,
  });

  factory _RivalBoardEntry.bot(_PracticeRival rival) => _RivalBoardEntry(
    name: rival.name,
    subtitle: rival.specialty,
    icon: rival.icon,
    color: rival.color,
    score: rival.score,
    isCurrentUser: false,
  );

  factory _RivalBoardEntry.currentUser(_LeaderboardEntry user) =>
      _RivalBoardEntry(
        name: user.username,
        subtitle: 'Your live reading score',
        icon: Icons.person_rounded,
        color: Constants.cocoa,
        score: user.weeklyScore,
        isCurrentUser: true,
      );
}

const List<_LeagueDefinition> _leagueDefinitions = [
  _LeagueDefinition(
    name: 'Scribbler (Beginner)',
    shortName: 'Scribbler',
    icon: Icons.edit_rounded,
    gradient: [Constants.sky, Constants.surfaceAlt],
  ),
  _LeagueDefinition(
    name: 'Storyteller',
    shortName: 'Storyteller',
    icon: Icons.auto_stories_rounded,
    gradient: [Constants.butter, Constants.surface],
  ),
  _LeagueDefinition(
    name: 'Reader',
    shortName: 'Reader',
    icon: Icons.chrome_reader_mode_rounded,
    gradient: [Constants.sky, Constants.butter],
  ),
  _LeagueDefinition(
    name: 'Novel Enthusiast',
    shortName: 'Novel',
    icon: Icons.menu_book_rounded,
    gradient: [Constants.surfaceAlt, Constants.sky],
  ),
  _LeagueDefinition(
    name: 'Page Turner',
    shortName: 'Page Turner',
    icon: Icons.book_rounded,
    gradient: [Constants.surface, Constants.butter],
  ),
  _LeagueDefinition(
    name: 'Bookworm',
    shortName: 'Bookworm',
    icon: Icons.local_library_rounded,
    gradient: [Constants.sky, Constants.butter],
  ),
  _LeagueDefinition(
    name: 'Plot Navigator',
    shortName: 'Navigator',
    icon: Icons.explore_rounded,
    gradient: [Constants.surfaceAlt, Constants.sky],
  ),
  _LeagueDefinition(
    name: 'Literary Champion',
    shortName: 'Champion',
    icon: Icons.emoji_events_rounded,
    gradient: [Constants.butter, Constants.surface],
  ),
  _LeagueDefinition(
    name: 'Epic Reader',
    shortName: 'Epic',
    icon: Icons.workspace_premium_rounded,
    gradient: [Constants.sky, Constants.surfaceAlt],
  ),
  _LeagueDefinition(
    name: 'Legendary Librarian',
    shortName: 'Legendary',
    icon: Icons.military_tech_rounded,
    gradient: [Constants.butter, Constants.sky],
  ),
];
