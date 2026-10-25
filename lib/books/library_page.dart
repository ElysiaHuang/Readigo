import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'book_tile.dart';
import 'review.dart';

class LibraryPage extends StatefulWidget {
  final String friendCode;
  const LibraryPage({super.key, required this.friendCode});
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final _books = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
  bool _loading = false, _hasMore = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('libraries')
          .doc(widget.friendCode)
          .collection('books')
          .orderBy('updatedAt', descending: true)
          .limit(20);
      if (_books.isNotEmpty) query = query.startAfterDocument(_books.last);
      final page = await query.get();
      if (!mounted) return;
      setState(() {
        _books.addAll(page.docs);
        _hasMore = page.docs.length == 20;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not load your library. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your Library')),
    body: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _books.length + 1,
      itemBuilder: (context, index) {
        if (index == _books.length) {
          return Column(
            children: [
              if (_error != null) Text(_error!),
              if (_books.isEmpty && !_loading && _error == null)
                const Text('No saved books yet.'),
              if (_hasMore)
                TextButton(
                  onPressed: _loading ? null : _load,
                  child: Text(
                    _loading
                        ? 'Loading…'
                        : _error != null
                        ? 'Retry'
                        : 'Load more',
                  ),
                ),
            ],
          );
        }
        final book = _books[index].data();
        return Column(
          children: [
            BookTile(
              bookId: book['bookId']?.toString() ?? '',
              bookImageurl: book['imageurl']?.toString() ?? '',
              title: book['title']?.toString() ?? 'Untitled',
              author: book['author']?.toString() ?? '',
              pages: book['pages'] as int? ?? 0,
              genre: '',
              shopurl: '',
              review: true,
              rating: book['rating'] as int? ?? 1,
              reviewText: book['review']?.toString() ?? '',
            ),
            TextButton(
              onPressed: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => BookReviewPage(
                          bookId: book['bookId']?.toString() ?? '',
                          title: book['title']?.toString() ?? 'Untitled',
                          author: book['author']?.toString() ?? '',
                          imageurl: book['imageurl']?.toString() ?? '',
                          pages: book['pages'] as int? ?? 0,
                          initialRating: book['rating'] as int? ?? 1,
                          initialReview: book['review']?.toString() ?? '',
                          returnToLibrary: true,
                        ),
                  ),
                );
                if (!mounted || updated != true) return;
                setState(() {
                  _books.clear();
                  _hasMore = true;
                });
                await _load();
              },
              child: const Text('Edit review'),
            ),
          ],
        );
      },
    ),
  );
}
