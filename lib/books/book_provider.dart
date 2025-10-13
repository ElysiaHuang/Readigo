import 'package:flutter/foundation.dart';

import 'book.dart';

class BookProvider extends ChangeNotifier{
  Book? _book;

  Book? get book => _book;

  void setBook(Book newBook){
    _book = newBook;
    notifyListeners();
  }

  void clearBook() {
    _book = null;
    notifyListeners();
  }
}