import 'dart:convert';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:testapp3/quiz/quizquestion.dart';

class quizscreen extends StatefulWidget {
  final String book;
  final int numberOfQuestion;
  final int difficulty;
  const quizscreen({super.key,required this.book,required this.numberOfQuestion,required this.difficulty});

  @override
  State<quizscreen> createState() => _quizscreenState();
}

class _quizscreenState extends State<quizscreen> {
  List<dynamic> questions = [];

  late final OpenAI _openAI;
  bool _isLoading = true;

  @override
  void initState() {
    // Initialize ChatGPT SDK
    _openAI = OpenAI.instance.build(
      token: dotenv.env['openai_key'],
      baseOption: HttpSetup(
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    _handleInitialMessage();
    super.initState();
  }
  Future<void> _handleInitialMessage() async {
    String userPrompt = "Give me ${widget.numberOfQuestion} questions on the book ${widget.book}."
        "If the difficulty scale was 1-5, make the questions at level ${widget.difficulty}."
        "Give the questions, 4 choices, and the correct answer in a dictionary format like this:"
        "[{\"question\": \"What is blah\", \"choices\": [\"choice1\", \"choice2\", \"choice3\", \"choice4\"], \"answer\": 0}]"
        "Each question should be in its own dictionary. The 'answer' key should be the index of the correct answer from"
        "the \"choices\" list."
        "Only give me the list of dictionaries. Do not put a beginning \"spiel\" or any formatting. Give me only the raw data.";

    final request = ChatCompleteText(
      messages: [
        Map.of({"role": "user", "content": userPrompt})
      ],
      model: Gpt4OChatModel(),
      maxToken: 1500,
    );
    ChatCTResponse? response = await _openAI.onChatCompletion(request: request);

    setState(() {
      String rawData = response!.choices.first.message!.content.trim();
      _isLoading = false;

      // Parse string into JSON object
      questions = jsonDecode(rawData);
      print(questions);
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(
        centerTitle: true,
        toolbarHeight: 70,
        title: Center(
          child: Row(
            children: [
              Text("Readigo",
                style: TextStyle(
                    color: Colors.lightBlueAccent,
                    fontWeight: FontWeight.w500,
                    shadows: [Shadow(color: Colors.greenAccent,offset: Offset(3, 3),blurRadius: 15)]
                ),
              ),
              Image.asset(height: 87,"assets/images/ReadigoLogo.png")

            ],
          ),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Text("Quiz",style: TextStyle(fontSize: 35,fontFamily: "Voltaire"),),
            SizedBox(
              height: 630,
              child: PageView(
                children: [
                  if (!_isLoading)
                    for (var questionMap in questions)
                      Quizquestion(
                        question: questionMap["question"],
                        choices: List<String>.from(questionMap["choices"]),
                      )
                  else
                    Center(child: SizedBox(width: 50, height: 50, child: const CircularProgressIndicator())),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: (){

              },
              child: Container(
                child: Center(child: Text(
                  "Start Quiz",
                  style: TextStyle(color: Color(0xFF00C8B3),
                    fontSize: 20,),
                  textAlign: TextAlign.center,
                )),
                width: 120, height: 50,
              ),
              style: OutlinedButton.styleFrom(
                  backgroundColor: Color(0xFFEBFFEE),
                  foregroundColor: Color(0xFF41BF41),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)
                )

              ),
            ),
          ],
        ),
      ),
    );
  }
}
