import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testapp3/components/page_intro.dart';
import 'package:testapp3/components/reading_cat.dart';
import 'package:testapp3/quiz/quiz_setup.dart';
import 'package:testapp3/util/book_service.dart';
import 'package:testapp3/util/constants.dart';

import 'book.dart';
import 'book_provider.dart';
import 'book_tile.dart';

class BookScreen extends StatefulWidget {
  final bool selectBookForQuiz;

  const BookScreen({super.key, this.selectBookForQuiz = false});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  final booknamecontroller = TextEditingController();
  final bookService = BookService();
  Future<List<Book>>? _futureBooks;

  void _selectBookForQuiz(Book book) {
    if (!book.supportsQuiz) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This title is missing a valid catalog entry. Choose another edition for a quiz.',
          ),
        ),
      );
      return;
    }
    context.read<BookProvider>().setBook(book);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const QuizSetupPage()),
    );
  }

  void _search() {
    final query = booknamecontroller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _futureBooks = Future.value([]);
      });
      return;
    }
    setState(() {
      _futureBooks = bookService.searchBooks(query);
    });
  }

  @override
  void dispose() {
    booknamecontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageIntro(
          title: widget.selectBookForQuiz ? 'Choose a Book' : 'Library',
          subtitle:
              widget.selectBookForQuiz
                  ? 'Pick one to continue.'
                  : 'Search by title, author, or ISBN.',
        ),
        const SizedBox(height: 16),
        _buildSearchBar(),
        const SizedBox(height: 16),
        Expanded(
          child:
              _futureBooks == null
                  ? _buildWelcomeSearchState()
                  : FutureBuilder<List<Book>>(
                    future: _futureBooks,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return _buildEmptyState(
                          icon: Icons.error_outline_rounded,
                          title: 'Search failed',
                          message: snapshot.error.toString(),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _buildEmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No results',
                          message: 'Try another search.',
                        );
                      }

                      final books = snapshot.data!;
                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 18),
                        itemCount: books.length,
                        itemBuilder: (context, index) {
                          final book = books[index];
                          return BookTile(
                            bookId: book.id,
                            review: false,
                            bookImageurl: book.thumbnailUrl,
                            title: book.title,
                            author: book.authors.join(" "),
                            description: book.description ?? "",
                            pages: book.pageCount,
                            genre: book.genre,
                            shopurl: book.shopurl.toString(),
                            onTapOverride:
                                widget.selectBookForQuiz
                                    ? () => _selectBookForQuiz(book)
                                    : null,
                          );
                        },
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Constants.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Constants.outline, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Constants.mutedInk),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: booknamecontroller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Title or author',
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: _search,
            style: FilledButton.styleFrom(
              backgroundColor: Constants.cocoa,
              foregroundColor: Colors.white,
              side: const BorderSide(color: Constants.outline, width: 1.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Constants.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Constants.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: Constants.mutedInk),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Constants.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Constants.mutedInk,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSearchState() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Constants.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Constants.outline, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Constants.cocoa.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR READING LIST',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                          color: Constants.mutedInk,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Ready for the next chapter?',
                        style: TextStyle(
                          fontSize: 21,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: Constants.ink,
                        ),
                      ),
                      SizedBox(height: 9),
                      Text(
                        'Search for a book to add it to your shelf or create a quiz.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Constants.mutedInk,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const ReadingCat(
                  size: 118,
                  semanticLabel: 'A cat ready to read',
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(color: Constants.outline, height: 1),
            const SizedBox(height: 13),
            const Row(
              children: [
                Icon(Icons.search_rounded, size: 17, color: Constants.cocoa),
                SizedBox(width: 8),
                Text(
                  'Use the search field above to begin.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Constants.cocoa,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
