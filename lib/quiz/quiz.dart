import 'package:testapp3/util/firebase_utils.dart';
import 'package:flutter/material.dart';
import 'package:testapp3/quiz/quiz_result.dart';
import 'package:testapp3/quiz/quiz_setup.dart';
import 'package:testapp3/util/constants.dart';
import 'package:testapp3/util/openai_prompt.dart';

class QuizScreen extends StatefulWidget {
  final String book;
  final String bookId;
  final int numberOfQuestion;
  final int difficulty;
  final String? chapterScope;

  const QuizScreen({
    super.key,
    required this.book,
    required this.bookId,
    required this.numberOfQuestion,
    required this.difficulty,
    this.chapterScope,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<dynamic> questions = [];
  List<int> selectedAnswers = [];
  bool _isLoading = true;
  int _currentPage = 0;
  final PageController _pageController = PageController();

  bool isReported = false;
  bool _submitting = false;
  String? _attemptId;
  String? _error;

  void _goToQuizHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const QuizSetupPage()),
      (route) => false,
    );
  }

  Future<void> loadQuestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await OpenaiPrompt.generateQuizQuestions(
        widget.numberOfQuestion,
        widget.bookId,
        widget.difficulty,
        chapterScope: widget.chapterScope,
      );
      if (!mounted) return;
      setState(() {
        questions = result['questions'] as List;
        _attemptId = result['attemptId'] as String;
        selectedAnswers = List.filled(questions.length, -1);
        _currentPage = 0;
        _isLoading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _reportContent() {
    if (_attemptId == null) return;
    if (isReported) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Report already sent.")));
      return;
    }

    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Report"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: "What looks wrong?",
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                final reason = controller.text.trim();
                if (reason.isEmpty) return;
                Navigator.pop(context);
                _sendReport(reason);
              },
              child: const Text("Send", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendReport(String reason) async {
    try {
      await FirebaseUtils.service.reportQuiz(_attemptId!, _currentPage, reason);
      if (!mounted) return;
      setState(() => isReported = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Report sent.')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  void updateSelectedAnswer(int index, int value) {
    setState(() {
      selectedAnswers[index] = value;
    });
  }

  void _goPrevious() {
    if (_currentPage == 0) return;
    _pageController.animateToPage(
      _currentPage - 1,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  void _goNext() {
    if (_currentPage >= questions.length - 1) return;
    _pageController.animateToPage(
      _currentPage + 1,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finishQuiz() async {
    if (_submitting || _attemptId == null) return;
    if (selectedAnswers.contains(-1)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Answer every question before finishing.'),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await FirebaseUtils.service.submitQuiz(
        _attemptId!,
        selectedAnswers,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => QuizResultPage(result: result)),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: _goToQuizHome,
          ),
          title: const Text('Quiz Time'),
          actions: [
            IconButton(
              icon: Icon(
                Icons.flag_outlined,
                color: isReported ? Colors.redAccent : Constants.ink,
              ),
              onPressed: _reportContent,
            ),
          ],
        ),
        backgroundColor: Constants.background,
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        TextButton(
                          onPressed: loadQuestions,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                  : Column(
                    children: [
                      _buildTopCard(),
                      const SizedBox(height: 14),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged:
                              (page) => setState(() => _currentPage = page),
                          itemCount: questions.length,
                          itemBuilder: (context, index) {
                            final question = questions[index];
                            return _buildQuestionCard(index, question);
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildBottomBar(),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildTopCard() {
    final progress =
        questions.isEmpty ? 0.0 : (_currentPage + 1) / questions.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Constants.surface, Constants.surfaceAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Constants.border),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: Constants.surface,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Constants.ink,
                  ),
                ),
              ),
              Text(
                '${_currentPage + 1}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Constants.ink,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.book,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Constants.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildMiniChip(
                      widget.chapterScope == null
                          ? 'Whole Book'
                          : widget.chapterScope!,
                    ),
                    _buildMiniChip('D${widget.difficulty}'),
                    _buildMiniChip('${widget.numberOfQuestion}Q'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Constants.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Constants.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 140),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Constants.ink,
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index, dynamic question) {
    final choices = List<String>.from(question['choices'] as List);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Constants.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Constants.border),
      ),
      child: LayoutBuilder(
        builder:
            (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildMiniChip('Q${index + 1}'),
                        const Spacer(),
                        const Text(
                          'Tap one',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Constants.mutedInk,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question['question'],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Constants.ink,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ...List.generate(choices.length, (choiceIndex) {
                      final isSelected = selectedAnswers[index] == choiceIndex;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: choiceIndex == choices.length - 1 ? 0 : 10,
                        ),
                        child: _buildChoiceTile(
                          label: String.fromCharCode(65 + choiceIndex),
                          text: choices[choiceIndex],
                          isSelected: isSelected,
                          onTap: () => updateSelectedAnswer(index, choiceIndex),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildChoiceTile({
    required String label,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? Constants.sky : Constants.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? Constants.ink : Constants.border,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isSelected ? Constants.ink : Constants.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : Constants.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  color: Constants.ink,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final isLast = _currentPage == questions.length - 1;
    final visibleIndexes = _visibleIndicatorIndexes();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Constants.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Constants.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_currentPage + 1} / ${questions.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Constants.mutedInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                visibleIndexes
                    .map(
                      (index) => Container(
                        width: index == _currentPage ? 20 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color:
                              index == _currentPage
                                  ? Constants.ink
                                  : Constants.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: _currentPage == 0 ? null : _goPrevious,
                  style: FilledButton.styleFrom(
                    backgroundColor: Constants.surfaceAlt,
                    foregroundColor: Constants.ink,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed:
                      _submitting
                          ? null
                          : isLast
                          ? _finishQuiz
                          : _goNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: Constants.ink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _submitting
                        ? 'Saving…'
                        : isLast
                        ? 'Finish'
                        : 'Next',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<int> _visibleIndicatorIndexes() {
    const maxVisible = 7;
    if (questions.length <= maxVisible) {
      return List<int>.generate(questions.length, (index) => index);
    }

    var start = _currentPage - 3;
    if (start < 0) start = 0;

    var end = start + maxVisible;
    if (end > questions.length) {
      end = questions.length;
      start = end - maxVisible;
    }

    return List<int>.generate(end - start, (index) => start + index);
  }
}
