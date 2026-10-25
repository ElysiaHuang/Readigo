import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testapp3/homepage.dart';
import 'package:testapp3/quiz/quiz.dart';
import 'package:testapp3/util/constants.dart';

import '../books/book_provider.dart';

class QuizSetupPage extends StatefulWidget {
  const QuizSetupPage({super.key});

  @override
  State<QuizSetupPage> createState() => _QuizSetupPageState();
}

class _QuizSetupPageState extends State<QuizSetupPage> {
  int _questionDifficulty = 4;
  int _numberOfQuestions = 10;

  static const List<_QuizChoice> _difficultyChoices = [
    _QuizChoice(
      value: 2,
      title: 'Easy',
      subtitle: 'Warm-up',
      icon: Icons.spa_rounded,
    ),
    _QuizChoice(
      value: 4,
      title: 'Medium',
      subtitle: 'Balanced',
      icon: Icons.bolt_rounded,
    ),
    _QuizChoice(
      value: 8,
      title: 'Hard',
      subtitle: 'Deeper',
      icon: Icons.local_fire_department_rounded,
    ),
    _QuizChoice(
      value: 12,
      title: 'Expert',
      subtitle: 'Sharpest',
      icon: Icons.workspace_premium_rounded,
    ),
  ];

  static const List<_QuizChoice> _questionChoices = [
    _QuizChoice(
      value: 5,
      title: '5',
      subtitle: 'Quick',
      icon: Icons.looks_5_rounded,
    ),
    _QuizChoice(
      value: 10,
      title: '10',
      subtitle: 'Standard',
      icon: Icons.filter_9_plus_rounded,
    ),
    _QuizChoice(
      value: 15,
      title: '15',
      subtitle: 'Focused',
      icon: Icons.grid_view_rounded,
    ),
    _QuizChoice(
      value: 20,
      title: '20',
      subtitle: 'Long',
      icon: Icons.view_agenda_rounded,
    ),
    _QuizChoice(
      value: 25,
      title: '25',
      subtitle: 'Full',
      icon: Icons.dashboard_customize_rounded,
    ),
  ];

  void _goBackToBooks() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage(initialpage: 2)),
    );
  }

  void _openBookSelection() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomePage(initialpage: 2, selectBookForQuiz: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = context.watch<BookProvider>().book;
    final canStartQuiz = book?.supportsQuiz ?? false;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: _goBackToBooks,
        ),
        title: const Text('Quiz Builder'),
        backgroundColor: Constants.appBar,
        foregroundColor: Constants.ink,
        surfaceTintColor: Colors.transparent,
      ),
      backgroundColor: Constants.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChallengeHero(book),
            const SizedBox(height: 18),
            _buildDirectionsCard(),
            const SizedBox(height: 14),
            _buildOptionSection(
              title: '1. Difficulty',
              icon: Icons.tune_rounded,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    _difficultyChoices
                        .map(
                          (choice) => _buildChoiceChip(
                            choice: choice,
                            isSelected: _questionDifficulty == choice.value,
                            onTap: () {
                              setState(() {
                                _questionDifficulty = choice.value;
                              });
                            },
                          ),
                        )
                        .toList(),
              ),
            ),
            const SizedBox(height: 14),
            _buildOptionSection(
              title: '2. Questions',
              icon: Icons.layers_rounded,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    _questionChoices
                        .map(
                          (choice) => _buildChoiceChip(
                            choice: choice,
                            isSelected: _numberOfQuestions == choice.value,
                            onTap: () {
                              setState(() {
                                _numberOfQuestions = choice.value;
                              });
                            },
                          ),
                        )
                        .toList(),
              ),
            ),
            const SizedBox(height: 14),
            _buildSummaryCard(),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    !canStartQuiz
                        ? null
                        : () {
                          final selectedBook = book;
                          if (selectedBook == null) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => QuizScreen(
                                    book: selectedBook.title,
                                    bookId: selectedBook.id,
                                    numberOfQuestion: _numberOfQuestions,
                                    difficulty: _questionDifficulty,
                                  ),
                            ),
                          );
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      !canStartQuiz
                          ? Constants.sky.withValues(alpha: 0.45)
                          : Constants.sky,
                  foregroundColor: Constants.ink,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Start Quiz',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Constants.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Constants.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.explore_rounded, color: Constants.ink, size: 20),
              SizedBox(width: 8),
              Text(
                'How This Works',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Constants.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDirectionLine('1', 'Choose a book.'),
          _buildDirectionLine('2', 'Choose a difficulty level.'),
          _buildDirectionLine('3', 'Choose how many questions you want.'),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Constants.surfaceAlt,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'Questions are AI-generated and may contain mistakes. Report anything that looks wrong. This quiz uses the whole book.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Constants.ink,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionLine(String step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Constants.sky,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              step,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Constants.ink,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Constants.ink,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeHero(dynamic book) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Constants.surface, Constants.surfaceAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Constants.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child:
          book == null
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pick a book',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Constants.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose a title to begin.',
                    style: TextStyle(fontSize: 14, color: Constants.mutedInk),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: _openBookSelection,
                    icon: const Icon(Icons.menu_book_rounded),
                    label: const Text('Open Books'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Constants.ink,
                      side: const BorderSide(color: Constants.border),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              )
              : Row(
                children: [
                  Container(
                    width: 82,
                    height: 118,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Constants.border),
                      color: Constants.surfaceAlt,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child:
                        book.thumbnailUrl.isEmpty
                            ? const Icon(
                              Icons.menu_book_rounded,
                              color: Constants.mutedInk,
                              size: 34,
                            )
                            : Image.network(
                              book.thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => const Icon(
                                    Icons.menu_book_rounded,
                                    color: Constants.mutedInk,
                                    size: 34,
                                  ),
                            ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selected',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Constants.mutedInk,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          book.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Constants.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          book.authors.join(' '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Constants.mutedInk,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _openBookSelection,
                          icon: const Icon(Icons.swap_horiz_rounded),
                          label: const Text('Change'),
                          style: TextButton.styleFrom(
                            foregroundColor: Constants.ink,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildOptionSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Constants.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Constants.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Constants.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Constants.ink, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Constants.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildChoiceChip({
    required _QuizChoice choice,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 112,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? Constants.sky : Constants.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? Constants.ink : Constants.border,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(choice.icon, color: Constants.ink, size: 22),
            const SizedBox(height: 12),
            Text(
              choice.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Constants.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              choice.subtitle,
              style: const TextStyle(fontSize: 12, color: Constants.mutedInk),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Constants.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Constants.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ready',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Constants.mutedInk,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final tiles = [
                _buildSummaryTile(
                  icon: Icons.quiz_outlined,
                  value: '$_numberOfQuestions',
                  label: 'questions',
                ),
                _buildSummaryTile(
                  icon: Icons.bolt_rounded,
                  value: '$_questionDifficulty',
                  label: 'difficulty',
                ),
                _buildSummaryTile(
                  icon: Icons.menu_book_rounded,
                  value: 'Whole book',
                  label: 'scope',
                ),
              ];

              if (constraints.maxWidth < 420) {
                return Column(
                  children: [
                    for (var i = 0; i < tiles.length; i++) ...[
                      if (i != 0) const SizedBox(height: 10),
                      tiles[i],
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: tiles[0]),
                  const SizedBox(width: 10),
                  Expanded(child: tiles[1]),
                  const SizedBox(width: 10),
                  Expanded(child: tiles[2]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Constants.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Constants.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: Constants.ink, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Constants.ink,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
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
}

class _QuizChoice {
  final int value;
  final String title;
  final String subtitle;
  final IconData icon;

  const _QuizChoice({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
