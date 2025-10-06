import 'package:flutter/material.dart';

class BookPreview extends StatefulWidget {
  final String bookImageurl;
  final String title;
  final String author;
  final String pages;
  final String grade;
  final String shopurl;
  const BookPreview({super.key,required this.bookImageurl,required this.title,required this.author,required this.pages,required this.grade,required this.shopurl});


  @override
  State<BookPreview> createState() => _BookPreviewState();
}

class _BookPreviewState extends State<BookPreview> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Readigo",
              style: TextStyle(
                  fontSize: 36,
                  color: Colors.lightBlueAccent,
                  fontWeight: FontWeight.w500,
                  shadows: [Shadow(color: Colors.greenAccent,offset: Offset(3, 3),blurRadius: 15)]
              ),
            ),
            Image.asset(height: 87,"assets/images/ReadigoLogo.png")

          ],
        ),
      ),
      body: Center(
        child: Column(children: [
          Text(widget.title,style: TextStyle(fontSize: 50,fontFamily: "Voltaire"),),
          Text(widget.author,style: TextStyle(fontSize:18,fontFamily:"Voltaire"),),
          Container(
             padding: EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [


                Expanded(
                    flex: 50,
                    child:Image.network(widget.bookImageurl)
                ),
                Expanded(
                  flex: 50,
                  child: Center(
                    child: Column(
                      children: [
                        Text(widget.pages,style: TextStyle(fontSize: 30,fontFamily: "Voltaire"),),
                        //Text((int.parse(widget.pages)*300).toString()+" words",style: TextStyle(fontSize: 30,fontFamily: "Voltaire"),),
                        Text("Grade Level:5-6",style: TextStyle(fontSize: 30,fontFamily: "Voltaire"),),
                      ],
                    ),
                  ),
                ),

              ],
            ),
          ),ElevatedButton(
            onPressed: (){

            },
            child: Container(
              child: Center(child: Text(
                "📖Read it",
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
          SizedBox(height: 20,),
          ElevatedButton(
            onPressed: (){

            },
            child: Container(
              child: Center(child: Text(
                "📝Quiz Me❓❓❓",
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
          SizedBox(height: 20,),
          ElevatedButton(
            onPressed: (){

            },
            child: Container(
              child: Center(child: Text(
                "Add to Library📚",
                style: TextStyle(color: Color(0xFF00C8B3),
                  fontSize: 20,),
                textAlign: TextAlign.center,
              )),
              width: 150, height: 50,
            ),
            style: OutlinedButton.styleFrom(
                backgroundColor: Color(0xFFEBFFEE),
                foregroundColor: Color(0xFF41BF41),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)
                )

            ),
          ),
        ],),
      ),
    );
  }
}
