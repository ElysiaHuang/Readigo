import 'dart:convert';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class gradebook extends StatefulWidget {
  const gradebook({super.key});

  @override
  State<gradebook> createState() => _gradebookState();
}

class _gradebookState extends State<gradebook> {
  late final OpenAI _openAI;
  bool _isLoading = true;
  String? response;
  String question1="nothing";
  List <String> question1options=[];
  String question1answer= "nothing";
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
    String userPrompt = "give me 5 multiple choice questions A,B,C,D on the book Hunger Games by Suzane Collins,put it in JSON format. Only return the json, don't add any formatting. I will parse it in my code. Do not add ```json";
    final request = ChatCompleteText(
      messages: [
        Map.of({"role": "user", "content": userPrompt})
      ],
      model: Gpt4OChatModel(),
      maxToken: 1500,
    );

    ChatCTResponse? chatCTResponse = await _openAI.onChatCompletion(
        request: request);

    response = chatCTResponse!.choices.first.message!.content.trim();
    Map<String, dynamic> parsedMap = jsonDecode(response.toString());
    final data = (parsedMap["questions"][0]);
    setState(() {
      _isLoading = false;
      question1 = (data["question"].toString());
      //question1options = (data["options"].toString());
      question1answer = (data["answer"].toString());
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("ChatGPT Example",)), body: Padding(
      padding: const EdgeInsets.all(15),
      child: !_isLoading
          ? ListView(
        physics: const ClampingScrollPhysics(),
        shrinkWrap: true,
        children: [
          Text(
            question1,
            style: const TextStyle(fontSize: 20),
          ),
          //Text(
            //question1options,
            //style: const TextStyle(fontSize: 20),
          //),
          Text(
            question1answer,
            style: const TextStyle(fontSize: 20),
          ),
        ],
      )
          : Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          child: const CircularProgressIndicator(),
        ),
      ),
    ));
  }
}

