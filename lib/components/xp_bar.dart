import 'package:flutter/material.dart';

class XPBar extends StatefulWidget {
  final int level;
  final int xp;
  final int nextLevelXp;
  final int? targetLevel; // for animation
  final int? targetXp; // for animation

  const XPBar({
    super.key,
    required this.level,
    required this.xp,
    required this.nextLevelXp,
    this.targetLevel,
    this.targetXp,
  });

  @override
  State<XPBar> createState() => _XPBarState();
}

class _XPBarState extends State<XPBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  late int displayLevel;
  late int displayXp;
  late int displayNextLevelXp;

  @override
  void initState() {
    super.initState();

    displayLevel = widget.level;
    displayXp = widget.xp;
    displayNextLevelXp = widget.nextLevelXp;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // If there's no animation target, initialize animation to the current XP value
    if (widget.targetLevel == null || widget.targetXp == null) {
      _animation = Tween<double>(begin: displayXp.toDouble(), end: displayXp.toDouble()).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      // set controller to completed so AnimatedBuilder reads the value immediately
      _controller.value = 1.0;
    } else {
      // placeholder; actual tween will be set in _runAnimation calls
      _animation = Tween<double>(begin: displayXp.toDouble(), end: displayXp.toDouble()).animate(_controller);
      // start the multi-step animation after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateXP();
      });
    }
  }

  void _animateXP() async {
    final targetLevel = widget.targetLevel!;
    final targetXp = widget.targetXp!;

    // Work on local copies so we can mutate them
    int curLevel = displayLevel;
    int curXp = displayXp;
    int curNext = displayNextLevelXp;

    while (curLevel < targetLevel || (curLevel == targetLevel && curXp < targetXp)) {
      final chunkEnd = (curLevel < targetLevel) ? curNext : targetXp;

      await _runAnimation(curXp, chunkEnd);

      // after running the animation to chunkEnd
      if (curLevel < targetLevel) {
        setState(() {
          curLevel++;
          curXp = 0;
          curNext = curLevel * 100;
          displayLevel = curLevel;
          displayXp = curXp;
          displayNextLevelXp = curNext;
        });
        // small pause between level-ups
        await Future.delayed(const Duration(milliseconds: 150));
      } else {
        // final chunk finished
        setState(() {
          curXp = chunkEnd;
          displayXp = curXp;
        });
        break;
      }
    }
  }

  Future<void> _runAnimation(int start, int end) async {
    _animation = Tween<double>(begin: start.toDouble(), end: end.toDouble()).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.reset();
    await _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        // If no animation target was provided, _animation already holds the static XP
        final currentXpAnimated = _animation.value;
        final percent = (displayNextLevelXp == 0) ? 0.0 : (currentXpAnimated / displayNextLevelXp).clamp(0.0, 1.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Level ${displayLevel}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("${currentXpAnimated.toInt()} / ${displayNextLevelXp} XP", style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 6),
            Stack(
              children: [
                Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: percent,
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF41BF41), Color(0xFF00C8B3)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}