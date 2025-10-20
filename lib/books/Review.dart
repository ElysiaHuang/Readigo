import 'package:flutter/material.dart';
class BookReviewPage extends StatefulWidget {
  final String title;
  final String author;
  const BookReviewPage({super.key,required this.title,required this.author});

  @override
  State<BookReviewPage> createState() => _BookReviewPageState();
}

class _BookReviewPageState extends State<BookReviewPage> {
  int starrating= 1;
  void changestarrating(int newrating){
    setState(() {
      starrating=newrating;
    });
  }
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
      child: Column(
        children: [
          Text(widget.title,style: TextStyle(fontSize: 30,fontFamily: "Voltaire"),),
          Text(widget.author, style: TextStyle(fontSize: 27,fontFamily: "Voltaire"),),
          SizedBox(height: 50,),
          SizedBox(
             width: 300,child: Text("Write a review (optional)",textAlign: TextAlign.start,),
          ),
          SizedBox( width: 300, height: 150,
            child: TextField(
              minLines: 5,
              maxLines: 5,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          SizedBox(
            height: 50,
          ),
          Text("Rate it out of 5 stars",style: TextStyle(fontSize: 30,fontFamily: "Voltaire"),),
          SizedBox(height: 100,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: (){
                  changestarrating(1);
                },
                  child: Icon((starrating>= 1)?Icons.star:Icons.star_border,size:80,color: (starrating>= 1)?Colors.yellow:Colors.black,)),
              GestureDetector(
                  onTap: (){
                    changestarrating(2);
                  },
                  child: Icon((starrating>= 2)?Icons.star:Icons.star_border,size:80,color: (starrating>= 2)?Colors.yellow:Colors.black,)),
              GestureDetector(
                  onTap: (){
                    changestarrating(3);
                  },
                  child: Icon((starrating>= 3)?Icons.star:Icons.star_border,size:80,color: (starrating>= 3)?Colors.yellow:Colors.black,)),
              GestureDetector(
                  onTap: (){
                    changestarrating(4);
                  },
                  child: Icon((starrating>= 4)?Icons.star:Icons.star_border,size:80,color: (starrating>= 4)?Colors.yellow:Colors.black,)),
              GestureDetector(
                  onTap: (){
                    changestarrating(5);
                  },
                  child: Icon((starrating>= 5)?Icons.star:Icons.star_border,size:80,color: (starrating>= 5)?Colors.yellow:Colors.black,)),


            ],
          ),
          SizedBox(
            height: 130,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () async {
                },
                style: OutlinedButton.styleFrom(
                    backgroundColor: Color(0xFFEBFFEE),
                    foregroundColor: Color(0xFF41BF41),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)
                    )

                ),
                child: Container(
                  width: 120, height: 50,
                  child: Center(child: Text(
                    "Cancel",
                    style: TextStyle(color: Color(0xFF00C8B3),
                      fontSize: 20,),
                    textAlign: TextAlign.center,
                  )),
                ),
              ),
              SizedBox(height: 20,),
              ElevatedButton(
                onPressed: (){
                },
                style: OutlinedButton.styleFrom(
                    backgroundColor: Color(0xFFEBFFEE),
                    foregroundColor: Color(0xFF41BF41),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)
                    )

                ),
                child: Container(
                  width: 120, height: 50,
                  child: Center(child: Text(
                    "Submit",
                    style: TextStyle(color: Color(0xFF00C8B3),
                      fontSize: 20,),
                    textAlign: TextAlign.center,
                  )),
                ),
              ),
            ],
          )
        ],
      ),
    )
    );
  }
}
