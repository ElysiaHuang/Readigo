import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class generatequizscreen extends StatefulWidget {
  const generatequizscreen({super.key});

  @override
  State<generatequizscreen> createState() => _generatequizscreenState();
}

class _generatequizscreenState extends State<generatequizscreen> {
  double _questionDifficulty=1;
  double _numberofquestions=5;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 25,),
        Text("Quiz",style: TextStyle(fontSize: 35,fontFamily: "Voltaire"),),
        SizedBox(height: 50,),
        Container(
          width:300 , height: 120,
          child: Center(
              child: Text(
                  "Tap here to \n select a book",
                textAlign: TextAlign.center,
              ),
          ),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey5,
            borderRadius: BorderRadius.circular(55)
          ),
        ),
        SizedBox(
          height: 60,
        ),
        Container(
          padding: EdgeInsets.only(
            left: 10,right: 10
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Question difficulty"),
              Text("Level ${_questionDifficulty.toInt()}")
            ],
          ),
        ),
        Slider(
          value: _questionDifficulty,
          min: 1,
          max: 12,
          divisions: 11,
          onChanged: (double value){
            setState(() {
              _questionDifficulty=value;
            });
          },
        ),
        Text("How hard should the questions be",style: TextStyle(color: CupertinoColors.systemGrey),),
        SizedBox(height: 50,),

        Container(
          padding: EdgeInsets.only(
              left: 10,right: 10
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Number of questions"),
              Text("${_numberofquestions.toInt()} questions")
            ],
          ),
        ),
        Slider(
          value: _numberofquestions,
          min: 5,
          max: 25,
          divisions: 4,
          onChanged: (double value){
            setState(() {
              _numberofquestions=value;
            });
          },
        ),
        Text("How many questions",style: TextStyle(color: CupertinoColors.systemGrey),),
        SizedBox(height: 40,),
        ElevatedButton(
          onPressed: (){},
          child: Container(
            child: Center(child: Text(
              "Start Quiz",
              style: TextStyle(color: Colors.black,
                  fontSize: 20,),
              textAlign: TextAlign.center,
            )),
            width: 120, height: 50,
          ),
          style: OutlinedButton.styleFrom(
              backgroundColor: Color(0xFFC0FFC0),
              foregroundColor: Color(0xFF41BF41)
          ),
        ),
      ],
    );
  }
}


