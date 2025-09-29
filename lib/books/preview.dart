import 'package:flutter/material.dart';

class BookPreview extends StatefulWidget {
  const BookPreview({super.key});

  @override
  State<BookPreview> createState() => _BookPreviewState();
}

class _BookPreviewState extends State<BookPreview> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(children: [
          Text("Maze Runner",style: TextStyle(fontSize: 50,fontFamily: "Voltaire"),),
          Text("James Dashner",style: TextStyle(fontSize:18,fontFamily:"Voltaire"),),
          Container(
             padding: EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [


                Expanded(
                    flex: 50,
                    child:Image.network("https://m.media-amazon.com/images/I/91Jra1QAMPL._UF1000,1000_QL80_.jpg")
                ),
                Expanded(
                  flex: 50,
                  child: Center(
                    child: Column(
                      children: [
                        Text("375 pages ",style: TextStyle(fontSize: 30,fontFamily: "Voltaire"),),
                        Text("100,000 words",style: TextStyle(fontSize: 30,fontFamily: "Voltaire"),),
                        Text("Grade Level:5-6",style: TextStyle(fontSize: 30,fontFamily: "Voltaire"),),
                      ],
                    ),
                  ),
                ),

              ],
            ),
          ),
        ],),
      ),
    );
  }
}
