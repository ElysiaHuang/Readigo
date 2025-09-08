import 'package:flutter/material.dart';

class Quizquestion extends StatefulWidget {
  final String question;
  final List <String> choices;
  const Quizquestion({super.key,required this.question,required this.choices,});

  @override
  State<Quizquestion> createState() => _QuizquestionState();
}

class _QuizquestionState extends State<Quizquestion> {
  @override
  Widget build(BuildContext context) {
   return  Column(
        children: [
          Text(widget.question,style: TextStyle(fontSize: 35,fontFamily: "Voltaire"),),
          for(String Choice in widget.choices)Column(
            children: [
              ElevatedButton(
                onPressed: (){
                },
                child: Container(
                  child: Center(child: Text(
                    Choice,
                    style: TextStyle(color: Colors.black,
                      fontSize: 20,),
                    textAlign: TextAlign.center,
                  )),
                  width: 230, height: 27,
                ),
                style: OutlinedButton.styleFrom(
                    backgroundColor: Color(0xFFC0FFC0),
                    foregroundColor: Color(0xFF41BF41)
                ),
              ),
              SizedBox(height: 12,)
            ],
          ),
        ],
    );
  }
}
