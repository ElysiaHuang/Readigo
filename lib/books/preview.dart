import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testapp3/books/review.dart';
import 'package:testapp3/books/book_provider.dart';
import 'package:testapp3/quiz/quiz_setup.dart';
import 'package:testapp3/util/constants.dart';
import 'package:url_launcher/url_launcher.dart';

import '../landing.dart';
import 'book.dart';

class BookPreview extends StatefulWidget {
  final String bookImageurl;
  final String bookId;
  final String title;
  final String author;
  final String description;
  final int pages;
  final String genre;
  final String shopurl;
  final bool review;
  final int rating;
  final String reviewText;

  const BookPreview({
    this.bookId = '',
    super.key,
    required this.bookImageurl,
    required this.title,
    required this.author,
    this.description = "",
    required this.pages,
    required this.genre,
    required this.shopurl,
    this.review = false,
    this.rating = 0,
    this.reviewText = "",
  });

  @override
  State<BookPreview> createState() => _BookPreviewState();
}

class _BookPreviewState extends State<BookPreview> {
  static const Color _pageBackground = Constants.background;
  static const Color _pageBackgroundBottom = Color(0xFFEAF8FF);
  static const Color _surface = Constants.surface;
  static const Color _surfaceSoft = Constants.surfaceAlt;
  static const Color _surfaceLine = Constants.border;
  static const Color _primary = Constants.ink;
  static const Color _primaryLight = Constants.sky;
  static const Color _accent = Constants.sky;
  static const Color _textPrimary = Constants.ink;
  static const Color _textMuted = Constants.mutedInk;

  User? currentUser = FirebaseAuth.instance.currentUser;

  Widget _headerTag(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _surfaceLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _surfaceLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: Icon(icon, color: _primary, size: 18),
          ),
          const SizedBox(height: 14),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w700,
              color: _textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildHeaderCover() {
    final coverContent =
        widget.bookImageurl.isEmpty
            ? Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            )
            : ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                widget.bookImageurl,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
              ),
            );

    if (widget.bookImageurl.isEmpty) {
      return _buildCoverFrame(coverContent);
    }

    return _buildCoverFrame(coverContent);
  }

  Widget _buildCoverFrame(Widget coverContent) {
    return Container(
      width: 126,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 170,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: SizedBox(height: 170, child: coverContent)),
        ],
      ),
    );
  }

  Widget _buildFullCoverPanel() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cover',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 320,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _surfaceSoft,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _surfaceLine),
            ),
            alignment: Alignment.center,
            child:
                widget.bookImageurl.isEmpty
                    ? const Icon(
                      Icons.menu_book_rounded,
                      size: 72,
                      color: _primary,
                    )
                    : Image.network(
                      widget.bookImageurl,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (context, error, stackTrace) => const Icon(
                            Icons.menu_book_rounded,
                            size: 72,
                            color: _primary,
                          ),
                    ),
          ),
        ],
      ),
    );
  }

  String get _readingTimeText {
    return '${((widget.pages / 50).ceil())} hours';
  }

  bool get _hasPageCount => widget.pages > 0;

  bool get _hasGenre => widget.genre.trim().isNotEmpty;

  Widget _detailTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _surfaceLine),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: Icon(icon, color: _primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: _textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _openPreviewLink(Uri uri) async {
    final modes = <LaunchMode>[
      LaunchMode.platformDefault,
      LaunchMode.inAppBrowserView,
      LaunchMode.externalApplication,
    ];

    for (final mode in modes) {
      try {
        if (await launchUrl(uri, mode: mode)) {
          return true;
        }
      } catch (_) {
        // Try the next available launch mode before giving up.
      }
    }

    return false;
  }

  // Show alert dialog to LOGIN if friend code is null
  void showLoginAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Login Required"),
          content: Text("Please log in to access this feature."),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            // go to start page
            TextButton(
              child: Text("Login"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LandingPage()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookprovider = context.read<BookProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        backgroundColor: Constants.appBar,
        foregroundColor: _textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      backgroundColor: _pageBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_pageBackground, _pageBackgroundBottom],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primary, _primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: _buildHeaderCover(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Voltaire',
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'by ${widget.author}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (_hasPageCount)
                                  _headerTag(
                                    Icons.auto_stories_outlined,
                                    '${widget.pages} pages',
                                  ),
                                if (_hasGenre)
                                  _headerTag(
                                    Icons.category_outlined,
                                    widget.genre,
                                  ),
                                if (_hasPageCount)
                                  _headerTag(
                                    Icons.schedule_outlined,
                                    _readingTimeText,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _buildFullCoverPanel(),
                const SizedBox(height: 18),
                _sectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reading Snapshot',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_hasPageCount || _hasGenre)
                        Row(
                          children: [
                            if (_hasPageCount)
                              Expanded(
                                child: _statCard(
                                  icon: Icons.menu_book_outlined,
                                  label: 'Page Count',
                                  value: '${widget.pages} pages',
                                ),
                              ),
                            if (_hasPageCount && _hasGenre)
                              const SizedBox(width: 12),
                            if (_hasGenre)
                              Expanded(
                                child: _statCard(
                                  icon: Icons.category_outlined,
                                  label: 'Genre',
                                  value: widget.genre,
                                ),
                              ),
                          ],
                        ),
                      if (_hasPageCount && _hasGenre)
                        const SizedBox(height: 12),
                      if (_hasPageCount)
                        _detailTile(
                          icon: Icons.schedule_outlined,
                          label: 'Estimated Reading Time',
                          value: _readingTimeText,
                        ),
                      if (!_hasPageCount && !_hasGenre)
                        const Text(
                          'Extra book details were not provided for this title.',
                          style: TextStyle(fontSize: 15, color: _textMuted),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                widget.review
                    ? ReviewWidget(
                      review: widget.reviewText,
                      rating: widget.rating,
                    )
                    : _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Actions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _actionButton(
                            icon: Icons.chrome_reader_mode_outlined,
                            label: 'Open Preview',
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final previewUrl = widget.shopurl.trim();
                              if (previewUrl.isEmpty) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Preview link is unavailable.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              final uri = Uri.parse(previewUrl);
                              if (!await _openPreviewLink(uri)) {
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Unable to open link.'),
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          _actionButton(
                            icon: Icons.quiz_outlined,
                            label: 'Start Quiz',
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            onPressed: () {
                              if (currentUser == null) {
                                showLoginAlert();
                                return;
                              }
                              if (!Book.hasQuizBookId(widget.bookId)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'This title is missing a valid catalog entry. Choose another edition for a quiz.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              bookprovider.setBook(
                                Book(
                                  id: widget.bookId,
                                  title: widget.title,
                                  authors: [widget.author],
                                  pageCount: widget.pages,
                                  description: widget.description,
                                  genre: widget.genre,
                                  thumbnailUrl: widget.bookImageurl,
                                  shopurl: widget.shopurl,
                                ),
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const QuizSetupPage(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _actionButton(
                            icon: Icons.library_add_outlined,
                            label: 'Add To Library',
                            backgroundColor: _surfaceSoft,
                            foregroundColor: _textPrimary,
                            onPressed: () {
                              if (currentUser == null) {
                                showLoginAlert();
                                return;
                              }

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => BookReviewPage(
                                        bookId: widget.bookId,
                                        title: widget.title,
                                        author: widget.author,
                                        imageurl: widget.bookImageurl,
                                        pages: widget.pages,
                                      ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReviewWidget extends StatelessWidget {
  final String review;
  final int rating;

  const ReviewWidget({super.key, required this.review, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: _BookPreviewState._surface,
        border: Border.all(color: _BookPreviewState._surfaceLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "review",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _BookPreviewState._textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 4,
            children: List.generate(
              rating,
              (index) => const Icon(
                Icons.star_rounded,
                size: 26,
                color: _BookPreviewState._accent,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            review,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: _BookPreviewState._textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
