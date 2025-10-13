import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testapp3/books/book_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../homepage.dart';
import 'book.dart';

class BookPreview extends StatefulWidget {
  final String bookImageurl;
  final String title;
  final String author;
  final int pages;
  final String grade;
  final String shopurl;
  const BookPreview({super.key,required this.bookImageurl,required this.title,required this.author,required this.pages,required this.grade,required this.shopurl});


  @override
  State<BookPreview> createState() => _BookPreviewState();
}

class _BookPreviewState extends State<BookPreview> {
  @override
  Widget build(BuildContext context) {
    final bookProvider = context.read<BookProvider>();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        automaticallyImplyLeading: true, // keeps back button if needed
        centerTitle: true, // centers within screen width
        title: Row(
          mainAxisSize: MainAxisSize.min, // only take as much space as needed
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Readigo',
              style: TextStyle(
                fontSize: 36,
                color: Colors.lightBlueAccent,
                fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(color: Colors.greenAccent,offset: Offset(3, 3),blurRadius: 15)
                  ]
              ),
            ),
            const SizedBox(width: 8),
            Image.asset(
              'assets/images/ReadigoLogo.png',
              height: 87,
              fit: BoxFit.contain,
            ),
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
                        Text(widget.pages.toString() + " pages",style: TextStyle(fontSize: 30,fontFamily: "Voltaire"),),
                        //Text((int.parse(widget.pages)*300).toString()+" words",style: TextStyle(fontSize: 30,fontFamily: "Voltaire"),),
                        Text("Grade Level:5-6",style: TextStyle(fontSize: 30,fontFamily: "Voltaire"),),
                      ],
                    ),
                  ),
                ),

              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final Uri url = Uri.parse(widget.shopurl);
              if(!await launchUrl(url)){
                throw Exception("Could not launch url: $url");
              }
            },
            style: OutlinedButton.styleFrom(
                backgroundColor: Color(0xFFEBFFEE),
                foregroundColor: Color(0xFF41BF41),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)
                )

            ),
            child: SizedBox(
              width: 120, height: 50,
              child: Center(child: Text(
                "📖Read it",
                style: TextStyle(color: Color(0xFF00C8B3),
                  fontSize: 20,),
                textAlign: TextAlign.center,
              )),
            ),
          ),
          SizedBox(height: 20,),
          ElevatedButton(
            onPressed: (){
              bookProvider.setBook(
                  Book(
                    title: widget.title,
                    authors: [widget.author],
                    pageCount: widget.pages,
                    thumbnailUrl: widget.bookImageurl,
                    shopurl: widget.shopurl,
                  )
              );
              Navigator.pop(context);
              Navigator.pushReplacement(
                  context, MaterialPageRoute(
                  builder: (_) => homepage(initialPage: 0)));
            },
            style: OutlinedButton.styleFrom(
                backgroundColor: Color(0xFFEBFFEE),
                foregroundColor: Color(0xFF41BF41),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)
                )

            ),
            child: SizedBox(
              width: 120, height: 50,
              child: Center(child: Text(
                "📝Quiz Me❓❓❓",
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
            child: SizedBox(
              width: 150, height: 50,
              child: Center(child: Text(
                "Add to Library📚",
                style: TextStyle(color: Color(0xFF00C8B3),
                  fontSize: 20,),
                textAlign: TextAlign.center,
              )),
            ),
          ),
        ],),
      ),
    );
  }
}
