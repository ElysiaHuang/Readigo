import 'dart:convert';

import '../books/book.dart';
import 'package:http/http.dart' as http;

import '../books/book.dart';
class BookService{
  final String _baseUrl = "https://www.googleapis.com/books/v1/volumes";
  Future<List<Book>> searchBooks(String query) async {
    final response=await http.get(Uri.parse("$_baseUrl?q=$query"));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List items = data["items"] ?? [];
      print("HELLLLLLO");
      return items.map((item) => Book.fromJson(item)).toList();
    } else {
      throw Exception("Failed to load books");
    }
  }
}