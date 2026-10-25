import 'package:flutter/material.dart';
import 'package:testapp3/components/xp_bar.dart';
import 'package:testapp3/quiz/quiz_setup.dart';
import '../util/constants.dart';

class QuizResultPage extends StatefulWidget {
  final Map<String, dynamic> result;
  const QuizResultPage({super.key, required this.result});
  List<dynamic> get questions => result['questions'] as List<dynamic>;
  List<int> get selectedAnswers => List<int>.from(result['selectedAnswers']);

  @override
  State<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends State<QuizResultPage> {
  late int correctCount;
  late int wrongCount;

  int? currentXp; // initial xp (from firestore)
  int? nextXp; // initial next_level_xp
  int? level; // initial level

  int? targetXp; // xp after gaining and leveling
  int? targetLevel; // level after leveling

  bool _isLoading = true;

  void _goToQuizHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const QuizSetupPage()),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    final result = widget.result;
    correctCount = result['correctCount'] as int;
    wrongCount = widget.questions.length - correctCount;
    currentXp = result['startXp'] as int;
    nextXp = result['startNextXp'] as int;
    level = result['startLevel'] as int;
    targetXp = result['targetXp'] as int;
    targetLevel = result['targetLevel'] as int;
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goToQuizHome();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Constants.appBar,
          foregroundColor: Constants.ink,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: _goToQuizHome,
          ),
          title: const Text("Quiz Results"),
          centerTitle: true,
        ),
        body: Container(
          color: Constants.background,
          child: LayoutBuilder(
            builder:
                (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          decoration: Constants.cardBox,
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Quiz Complete",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Score: $correctCount / ${widget.questions.length}",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Correct: $correctCount    Wrong: $wrongCount",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: Constants.cardBox,
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: List.generate(widget.questions.length, (
                              index,
                            ) {
                              final q = widget.questions[index];
                              return _buildQuestionResultCard(index, q);
                            }),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!_isLoading)
                          Column(
                            children: [
                              XPBar(
                                level: level!,
                                xp: currentXp!,
                                nextLevelXp: nextXp!,
                                targetXp: targetXp!,
                                targetLevel: targetLevel!,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                style: Constants.normalButton,
                                onPressed: _goToQuizHome,
                                child: const Text('Back to Quiz Builder'),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionResultCard(int index, dynamic q) {
    final choices = List<String>.from(q["choices"] ?? const []);
    final int correctIdx = q["answer"] is int ? q["answer"] as int : -1;
    final int selectedIdx =
        index < widget.selectedAnswers.length
            ? widget.selectedAnswers[index]
            : -1;

    final bool hasSelectedAnswer =
        selectedIdx >= 0 && selectedIdx < choices.length;
    final bool hasCorrectAnswer =
        correctIdx >= 0 && correctIdx < choices.length;
    final bool isCorrect = hasSelectedAnswer && selectedIdx == correctIdx;

    final yourAnswerText =
        hasSelectedAnswer ? choices[selectedIdx] : 'Not answered';
    final correctAnswerText =
        hasCorrectAnswer ? choices[correctIdx] : 'Unavailable';

    return Container(
      margin: EdgeInsets.only(
        bottom: index == widget.questions.length - 1 ? 0 : 12,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? Colors.green : Colors.red,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Q${index + 1}. ${q["question"]}",
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Your answer: $yourAnswerText",
            style: TextStyle(
              fontSize: 16,
              color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
            ),
          ),
          if (!isCorrect)
            Text(
              "Correct answer: $correctAnswerText",
              style: const TextStyle(fontSize: 16, color: Colors.green),
            ),
        ],
      ),
    );
  }
}
