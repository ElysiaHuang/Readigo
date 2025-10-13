import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testapp3/books/book_tile.dart';
import 'package:testapp3/homepage.dart';
import 'package:testapp3/quiz/quiz.dart';

import '../books/book_provider.dart';

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
    final book=context.watch<BookProvider>().book;
    return Column(
      children: [
        SizedBox(height: 25,),
        Text("Quiz",style: TextStyle(fontSize: 35,fontFamily: "Voltaire"),),
        SizedBox(height: 50,),
        (book==null)?
        GestureDetector(
          onTap: (){
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=>homepage(initialpage: 2)));
          },
          child: Container(
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
        ):BookTile(bookImageurl: book.thumbnailUrl, title: book.title, author: book.authors.join(" "), pages: book.pageCount, grade: "5-6", shopurl: book.shopurl),

        SizedBox(
          height: (book==null)?60:0,
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
          onPressed: (){
            if(book==null){
              null;
            }else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => quizscreen (book: book.title, numberOfQuestion: _numberofquestions.toInt(), difficulty: _questionDifficulty.toInt())));
            }


          },
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


