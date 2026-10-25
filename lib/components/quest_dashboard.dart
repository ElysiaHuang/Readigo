import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:testapp3/util/firebase_utils.dart';
import 'package:testapp3/util/constants.dart';

class QuestDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;
  const QuestDashboard({super.key, required this.userData});
  @override
  State<QuestDashboard> createState() => _QuestDashboardState();
}

class _QuestDashboardState extends State<QuestDashboard> {
  Timer? _clock;
  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questState = FirebaseUtils.buildQuestState(widget.userData);
    final now = DateTime.now().toUtc();
    final streakCount = questState['streakCount'] as int;
    final dailyProgress = Map<String, int>.from(
      questState['dailyQuestProgress'] as Map<String, int>,
    );
    final activityDates = Set<String>.from(
      questState['activityDates'] as List<String>,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStreakCard(
          streakCount: streakCount,
          activityDates: activityDates,
          now: now,
        ),
        const SizedBox(height: 18),
        _buildWeeklyReadingSprint(now: now, activityDates: activityDates),
        const SizedBox(height: 18),
        _buildDailyQuestSection(now: now, dailyProgress: dailyProgress),
      ],
    );
  }

  Widget _buildWeeklyReadingSprint({
    required DateTime now,
    required Set<String> activityDates,
  }) {
    final weekDates = _weekDatesFor(now);
    final activeDays =
        weekDates
            .where((date) => activityDates.contains(_dateKey(date)))
            .length;
    const goal = 5;
    final progress = math.min(1.0, activeDays / goal);
    final remaining = math.max(0, goal - activeDays);
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Constants.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Constants.outline, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Constants.cocoa.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Constants.blush,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Constants.outline),
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  color: Constants.cocoa,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly reading sprint',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Constants.ink,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Read or quiz on five days this week.',
                      style: TextStyle(fontSize: 13, color: Constants.mutedInk),
                    ),
                  ],
                ),
              ),
              Text(
                '$activeDays/$goal',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Constants.cocoa,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Constants.butter,
              valueColor: const AlwaysStoppedAnimation<Color>(Constants.cocoa),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(weekDates.length, (index) {
              final date = weekDates[index];
              final active = activityDates.contains(_dateKey(date));
              final today = _dateKey(date) == _dateKey(now);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: today ? Constants.cocoa : Constants.mutedInk,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? Constants.cocoa : Constants.butter,
                      border: Border.all(
                        color: today ? Constants.outline : Constants.border,
                        width: today ? 1.4 : 1,
                      ),
                    ),
                    child:
                        active
                            ? const Icon(
                              Icons.check_rounded,
                              size: 15,
                              color: Colors.white,
                            )
                            : null,
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 14),
          Text(
            activeDays >= goal
                ? 'Sprint complete. Keep the rhythm going.'
                : '$remaining more reading ${remaining == 1 ? 'day' : 'days'} to finish this week’s sprint.',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Constants.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard({
    required int streakCount,
    required Set<String> activityDates,
    required DateTime now,
  }) {
    final weekDates = _weekDatesFor(now);
    final weekdayLabels = const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Constants.butter, Constants.surface],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Constants.border),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 10,
            top: 10,
            child: Icon(
              Icons.local_fire_department_rounded,
              size: 88,
              color: Constants.sky.withValues(alpha: 0.28),
            ),
          ),
          Column(
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
              const SizedBox(height: 8),
              Text(
                streakCount == 0
                    ? 'Do a quiz today to start a new streak!'
                    : 'Keep your streak alive by finishing a quiz today.',
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: Color(0xFF707070),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: Constants.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (index) {
                    final date = weekDates[index];
                    final isToday = _dateKey(date) == _dateKey(now);
                    final isActive = activityDates.contains(_dateKey(date));

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          weekdayLabels[index],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color:
                                isToday
                                    ? Constants.ink
                                    : const Color(0xFFB2B2B2),
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
                            boxShadow:
                                isActive
                                    ? [
                                      BoxShadow(
                                        color: Constants.sky.withValues(
                                          alpha: 0.22,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                    : null,
                          ),
                          child:
                              isActive
                                  ? const Icon(
                                    Icons.local_fire_department_rounded,
                                    color: Colors.white,
                                    size: 19,
                                  )
                                  : null,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyQuestSection({
    required DateTime now,
    required Map<String, int> dailyProgress,
  }) {
    final timeUntilReset = _timeUntilReset(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 360;

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Quests',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: Constants.ink,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeUntilReset,
                        style: TextStyle(
                          color: Constants.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                const Expanded(
                  child: Text(
                    'Daily Quests',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                ),
                Icon(Icons.schedule_rounded, color: Constants.ink, size: 18),
                const SizedBox(width: 4),
                Text(
                  timeUntilReset,
                  style: TextStyle(
                    color: Constants.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Constants.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Constants.border),
          ),
          child: Column(
            children: List.generate(_dailyQuestDefinitions.length, (index) {
              final quest = _dailyQuestDefinitions[index];
              final progress = dailyProgress[quest.id] ?? 0;
              final isCompleted = progress >= quest.goal;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: _buildDailyQuestTile(
                      quest: quest,
                      progress: progress,
                      isCompleted: isCompleted,
                    ),
                  ),
                  if (index != _dailyQuestDefinitions.length - 1)
                    const Divider(height: 1, color: Color(0xFFF0F0F0)),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyQuestTile({
    required _DailyQuestDefinition quest,
    required int progress,
    required bool isCompleted,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: quest.iconBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(quest.icon, color: quest.iconColor, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quest.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4B4B4B),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 16,
                            value: math.min(
                              1.0,
                              math.max(0.0, progress / quest.goal),
                            ),
                            backgroundColor: const Color(0xFFE7E7E7),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isCompleted
                                  ? const Color(0xFF35B96B)
                                  : quest.iconColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$progress / ${quest.goal}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFAEAEAE),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          isCompleted
                              ? const Color(0xFFE8F7ED)
                              : quest.rewardBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.workspace_premium_rounded,
                      color:
                          isCompleted
                              ? const Color(0xFF35B96B)
                              : quest.rewardColor,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<DateTime> _weekDatesFor(DateTime now) {
    final daysSinceSunday = now.weekday % 7;
    final start = DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: daysSinceSunday));

    return List.generate(7, (index) => start.add(Duration(days: index)));
  }

  String _timeUntilReset(DateTime now) {
    final nextMidnight = DateTime.utc(now.year, now.month, now.day + 1);
    final remaining = nextMidnight.difference(now);
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    if (hours <= 0) {
      return '$minutes MIN';
    }
    if (minutes == 0) {
      return '$hours HOURS';
    }
    return '${hours}H ${minutes}M';
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _DailyQuestDefinition {
  final String id;
  final String title;
  final int goal;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Color rewardColor;
  final Color rewardBackground;

  const _DailyQuestDefinition({
    required this.id,
    required this.title,
    required this.goal,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.rewardColor,
    required this.rewardBackground,
  });
}

const List<_DailyQuestDefinition> _dailyQuestDefinitions = [
  _DailyQuestDefinition(
    id: 'earn_xp',
    title: 'Earn 20 XP',
    goal: 20,
    icon: Icons.bolt_rounded,
    iconColor: Constants.ink,
    iconBackground: Constants.butter,
    rewardColor: Constants.ink,
    rewardBackground: Constants.sky,
  ),
  _DailyQuestDefinition(
    id: 'finish_quizzes',
    title: 'Finish 2 quizzes',
    goal: 2,
    icon: Icons.menu_book_rounded,
    iconColor: Constants.ink,
    iconBackground: Constants.sky,
    rewardColor: Constants.ink,
    rewardBackground: Constants.butter,
  ),
  _DailyQuestDefinition(
    id: 'correct_answers',
    title: 'Get 10 answers correct',
    goal: 10,
    icon: Icons.timer_outlined,
    iconColor: Constants.ink,
    iconBackground: Constants.sky,
    rewardColor: Constants.ink,
    rewardBackground: Constants.butter,
  ),
];
