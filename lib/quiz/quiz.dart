import 'package:flutter/material.dart';
import 'package:testapp3/quiz/page_indicator.dart';
import 'package:testapp3/quiz/quiz_result.dart';
import 'package:testapp3/quiz/quizquestion.dart';
import 'package:testapp3/util/openai_prompt.dart';

import '../util/constants.dart';

class QuizScreen extends StatefulWidget {
  final String book;
  final int numberOfQuestion;
  final int difficulty;
  const QuizScreen({super.key,required this.book,required this.numberOfQuestion,required this.difficulty});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<dynamic> questions = [];
  List<int> selectedAnswers = [];
  bool _isLoading = true;
  int _currentPage = 0;

  void loadQuestions() async {
    questions = await OpenaiPrompt.generateQuizQuestions(widget.numberOfQuestion, widget.book, widget.difficulty);
    selectedAnswers = List.filled(questions.length, 0);

    setState(() {
      _isLoading = false;
      print(questions);
    });
  }

  void updateSelectedAnswer(int index, int value){
    setState(() {
      selectedAnswers[index] = value;
    });

    print(selectedAnswers);
  }

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Constants.defaultAppBar,
      body: Center(
        child: Column(
          children: [
            Text("Quiz",style: TextStyle(fontSize: 35,fontFamily: "Voltaire"),),
            SizedBox(height: 30,),
            Expanded(
              child: PageView(
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  if (!_isLoading)
                    ...questions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final questionMap = entry.value;

                      return QuizQuestion(
                        index: index,
                        selectedValue: selectedAnswers[index],
                        question: questionMap["question"],
                        choices: List<String>.from(questionMap["choices"]),
                        onChanged: updateSelectedAnswer,
                      );
                    })
                  else
                    const Center(
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),
            PageIndicator(count: questions.length, currentIndex: _currentPage),
            SizedBox(height: 20,),
            (!_isLoading) ? ElevatedButton(
              onPressed: (){
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => QuizResultPage(questions: questions, selectedAnswers: selectedAnswers, difficulty: widget.difficulty,)));
              },
              style: OutlinedButton.styleFrom(
                  backgroundColor: Color(0xFFEBFFEE),
                  foregroundColor: Color(0xFF41BF41),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)
                )

              ),
              child: SizedBox(
                width: 120, height: 50,
                child: Center(child: Text(
                  "Submit Quiz",
                  style: TextStyle(color: Color(0xFF00C8B3),
                    fontSize: 20,),
                  textAlign: TextAlign.center,
                )),
              ),
            ) : Container(),
            SizedBox(height: 50,)
          ],
        ),
      ),
    );
  }
}
