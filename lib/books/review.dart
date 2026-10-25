import 'package:testapp3/util/firebase_utils.dart';
import 'package:flutter/material.dart';
import 'package:testapp3/homepage.dart';
import 'package:testapp3/util/constants.dart';

class BookReviewPage extends StatefulWidget {
  final String bookId;
  final String title;
  final String author;
  final String imageurl;
  final int pages;
  final int initialRating;
  final String initialReview;
  final bool returnToLibrary;

  const BookReviewPage({
    this.initialRating = 1,
    this.initialReview = '',
    this.returnToLibrary = false,
    this.bookId = '',
    super.key,
    required this.title,
    required this.author,
    required this.imageurl,
    required this.pages,
  });

  @override
  State<BookReviewPage> createState() => _BookReviewPageState();
}

class _BookReviewPageState extends State<BookReviewPage> {
  final reviewController = TextEditingController();
  bool _saving = false;
  int starrating = 1;
  String reviewtext = "";

  @override
  void initState() {
    super.initState();
    starrating = widget.initialRating.clamp(1, 5);
    reviewController.text = widget.initialReview;
  }

  void changestarrating(int newrating) {
    setState(() {
      starrating = newrating;
    });
  }

  Future<void> addbooktolibrary() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await FirebaseUtils.service.saveBook({
        'bookId': widget.bookId,
        'title': widget.title,
        'author': widget.author,
        'imageurl': widget.imageurl,
        'rating': starrating,
        'review': reviewController.text.trim(),
        'pages': widget.pages,
      });

      // Show success message and navigate to profile
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Book added to your library!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        if (widget.returnToLibrary) {
          Navigator.pop(context, true);
          return;
        }
        // Navigate to profile page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage(initialpage: 4)),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add book. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add to Library'),
        backgroundColor: Constants.appBar,
        foregroundColor: Constants.ink,
      ),
      backgroundColor: Constants.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Constants.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.imageurl,
                        width: 80,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stack) => Container(
                              width: 80,
                              height: 120,
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.book,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.author,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Chip(label: Text('${widget.pages} pages')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Write a short review (optional)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reviewController,
                onChanged: (text) {
                  reviewtext = text;
                },
                maxLength: 2000,
                minLines: 4,
                maxLines: 6,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'What did you like about this book?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Rate it',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final starIndex = i + 1;
                  return IconButton(
                    icon: Icon(
                      starrating >= starIndex ? Icons.star : Icons.star_border,
                      color:
                          starrating >= starIndex ? Colors.amber : Colors.grey,
                      size: 36,
                    ),
                    onPressed: () => changestarrating(starIndex),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Constants.sky),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Cancel'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : addbooktolibrary,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.sky,
                        foregroundColor: Constants.ink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Submit', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
