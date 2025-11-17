import 'dart:convert';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenaiPrompt{
  static final OpenAI _openAI = OpenAI.instance.build(
    token: dotenv.env['openai_key'],
    baseOption: HttpSetup(
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  static Future<int> getBookGradeLevel(String bookTitle) async{
    String userPrompt = "You are a professional book grader. For the book \"$bookTitle\","
        "Give me your best estimate for the grade level in a dictionary format like this:"
        "{\"grade\": int}"
        "Only give me this dictionary. Do not put a beginning \"spiel\" or any formatting. Give me only the raw data.";

    final request = ChatCompleteText(
      messages: [
        Map.of({"role": "user", "content": userPrompt})
      ],
      model: Gpt4OChatModel(),
      maxToken: 1500,
    );
    ChatCTResponse? response = await _openAI.onChatCompletion(request: request);

    String rawData = response!.choices.first.message!.content.trim();
    // Parse string into JSON object
    final data = jsonDecode(rawData);
    return data["grade"];
  }

  static Future<List<dynamic>> generateQuizQuestions(int numberOfQuestions, String book, int difficulty) async {
    String userPrompt = "Give me $numberOfQuestions questions on the book $book."
        "If the difficulty scale was 1-5, make the questions at level $difficulty."
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

    String rawData = response!.choices.first.message!.content.trim();
    // Parse string into JSON object
    final questions = jsonDecode(rawData);
    return questions;
  }
}