import 'package:flutter/material.dart';
import 'package:testapp3/components/xp_bar.dart';
import 'package:testapp3/util/firebase_utils.dart';

import '../util/constants.dart';

class QuizResultPage extends StatefulWidget {
  final List<dynamic> questions;       // [{question, choices, answer}]
  final List<int> selectedAnswers;
  final int difficulty;

  const QuizResultPage({
    super.key,
    required this.questions,
    required this.selectedAnswers,
    required this.difficulty,
  });

  @override
  State<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends State<QuizResultPage> {
  late int correctCount;
  late int wrongCount;

  int? currentXp;      // initial xp (from firestore)
  int? nextXp;         // initial next_level_xp
  int? level;          // initial level

  int? targetXp;       // xp after gaining and leveling
  int? targetLevel;    // level after leveling

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateResults();
    _calculateXpGain();
  }

  void _calculateResults() {
    int correct = 0;

    for (int i = 0; i < widget.questions.length; i++) {
      if (widget.selectedAnswers[i] == widget.questions[i]["answer"]) {
        correct++;
      }
    }

    correctCount = correct;
    wrongCount = widget.questions.length - correct;
  }

  Future<void> _calculateXpGain() async {
    final gainedXp = correctCount * widget.difficulty;

    final friendCode = await FirebaseUtils.getCurrentUserFriendCode();
    final userData = await FirebaseUtils.getUserData(friendCode!);

    final int startXp = userData?["xp"];
    final int startNextXp = userData?["next_level_xp"];
    final int startLevel = userData?["level"];

    // temp working values
    int newXp = startXp + gainedXp;
    int newLevel = startLevel;
    int newNextXp = startNextXp;

    // apply level ups
    while (newXp >= newNextXp) {
      newXp -= newNextXp;
      newLevel++;
      newNextXp = newLevel * 100; // your rule
    }

    // Save new values to Firestore
    await FirebaseUtils.updateUser(friendCode, {
      "xp": newXp,
      "level": newLevel,
      "next_level_xp": newNextXp,
    });

    setState(() {
      // Initial state (before animation)
      currentXp = startXp;
      nextXp = startNextXp;
      level = startLevel;

      // Final state (where to animate to)
      targetXp = newXp;
      targetLevel = newLevel;

      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quiz Results"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Your Score",
              style: const TextStyle(
                fontSize: 32,
                fontFamily: "Voltaire",
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              "$correctCount / ${widget.questions.length}",
              style: const TextStyle(
                fontSize: 24,
                color: Colors.green,
              ),
            ),

            Text(
              "Correct: $correctCount    Wrong: $wrongCount",
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: widget.questions.length,
                itemBuilder: (context, index) {
                  final q = widget.questions[index];
                  final int correctIdx = q["answer"];
                  final int selectedIdx = widget.selectedAnswers[index];

                  final bool isCorrect = selectedIdx == correctIdx;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCorrect ? Colors.green : Colors.red,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Q${index + 1}. ${q["question"]}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "Your answer: ${q["choices"][selectedIdx]}",
                          style: TextStyle(
                            fontSize: 18,
                            color: isCorrect
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                          ),
                        ),

                        if (!isCorrect)
                          Text(
                            "Correct answer: ${q["choices"][correctIdx]}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            if (!_isLoading)
              XPBar(
                level: level!,
                xp: currentXp!,
                nextLevelXp: nextXp!,
                targetXp: targetXp!,
                targetLevel: targetLevel!,
              ),

            const SizedBox(height: 10),

            ElevatedButton(
              style: Constants.normalButton,
              onPressed: () => Navigator.pop(context),
              child: const Text("Back to Home"),
            ),
          ],
        ),
      ),
    );
  }
}
