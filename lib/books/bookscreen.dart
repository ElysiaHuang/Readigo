import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:testapp3/util/book_service.dart';

import 'book.dart';
import 'book_tile.dart';

class bookscreen extends StatefulWidget {
  const bookscreen({super.key});

  @override
  State<bookscreen> createState() => _bookscreenState();
}

class _bookscreenState extends State<bookscreen> {
  final booknamecontroller=TextEditingController();
  final bookService=BookService();
  Future<List<Book>>? _futureBooks;
  void _search() {
    setState(() {
      _futureBooks = bookService.searchBooks(booknamecontroller.text);
    });
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 25,),
        Text("Find a Book",style: TextStyle(fontSize: 35,fontFamily: "Voltaire"),),
        SizedBox(height: 50,),
        Container(
          height: 50, width: 320,
          decoration: BoxDecoration(
              color: CupertinoColors.extraLightBackgroundGray,
              borderRadius: BorderRadius.circular(20)

          ),
          child: Row(
            children: [
              Container(
                padding:
                EdgeInsets.only(
                    left: 25
                ),
                height: 36, width: 270,
                child: TextField(
                  controller: booknamecontroller,
                ),
              ),
              IconButton(onPressed: (){
                _search();
              }, icon: Icon(Icons.search,size: 33,))
            ],
          ),
        ),
        SizedBox(
          height: 60,
        ),
        Expanded(
          flex: 80,
          child: _futureBooks == null
              ? Center(child: Text("Search for a book"))
              : FutureBuilder<List<Book>>(
            future: _futureBooks,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text("No results"));
              }
              final books = snapshot.data!;
              print(books);
              return ListView.builder(
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  print(book);
                  return BookTile(
                    bookImageurl: book.thumbnailUrl ??
                        "https://via.placeholder.com/150",
                    title: book.title,
                    author: book.authors.join(
                      " "
                    ),
                    pages: book.pageCount,
                    grade: "book.gradeText", shopurl: book.shopurl.toString(),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
