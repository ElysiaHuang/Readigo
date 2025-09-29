import 'package:flutter/material.dart';

class BookTile extends StatelessWidget {
  final String bookImageurl;
  final String title;
  final String author;
  final String words;
  final String grade;
  const BookTile({super.key,required this.bookImageurl,required this.title,required this.author,required this.words,required this.grade});

  @override
  Widget build(BuildContext context) {
    return Container(
      height:250 , width: 333,
      margin: EdgeInsets.only(top: 35, bottom:30),
      padding: EdgeInsets.all(0.1),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: Color(0xfff2f2f7)
      ),
      child: Row(
        children: [


          Expanded(
            flex: 33,
            child:Image.network(bookImageurl)
          ),
          Expanded(
            flex: 66,
            child: Center(
              child: Column(
                children: [
                  Text(title,style: TextStyle(fontSize: 18,fontFamily: "Voltaire"),),
                  Text(author,style: TextStyle(fontSize: 18,fontFamily: "Voltaire"),),
                  Text(words,style: TextStyle(fontSize: 18,fontFamily: "Voltaire"),),
                  Text(grade,style: TextStyle(fontSize: 18,fontFamily: "Voltaire"),),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }
}
