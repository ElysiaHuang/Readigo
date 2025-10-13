import 'package:flutter/material.dart';
import 'package:testapp3/books/preview.dart';

class BookTile extends StatelessWidget {
  final String bookImageurl;
  final String title;
  final String author;
  final int pages;
  final String grade;
  final String shopurl;
  const BookTile({super.key,required this.bookImageurl,required this.title,required this.author,required this.pages,required this.grade,required this.shopurl });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (_)=>BookPreview(
          title: title,
          author: author,
          pages: pages,
          grade: grade,
          bookImageurl: bookImageurl,
          shopurl:shopurl
        )));
      },
      child: Container(
        height:220 , width: 350,
        margin: EdgeInsets.only(top: 20, bottom:19),
        padding: EdgeInsets.all(0.1),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: Color(0xfff2f2f7)
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center,
          children: [


            SizedBox(
              width: 100,
              child:Image.network(bookImageurl)
            ),
            SizedBox(
              width: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title,style: TextStyle(fontSize: 25,fontFamily: "Voltaire"),),
                    Text(author,style: TextStyle(fontSize: 22,fontFamily: "Voltaire"),),
                    Text(pages.toString()+" pages",style: TextStyle(fontSize: 21,fontFamily: "Voltaire"),),
                    //Text(grade,style: TextStyle(fontSize: 25,fontFamily: "Voltaire"),),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
