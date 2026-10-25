import 'package:flutter/material.dart';
import 'package:testapp3/books/preview.dart';
import 'package:testapp3/util/constants.dart';

class BookTile extends StatelessWidget {
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
  final VoidCallback? onTapOverride;

  const BookTile({
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
    this.onTapOverride,
  });

  Widget _buildCover() {
    if (bookImageurl.isEmpty) {
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        bookImageurl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Constants.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Constants.outline),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 36, color: Colors.grey[600]),
          SizedBox(height: 6),
          Text(
            "No Cover",
            style: TextStyle(color: Colors.grey[700], fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasGenre = genre.trim().isNotEmpty;
    final hasPages = pages > 0;

    return GestureDetector(
      onTap: () {
        if (onTapOverride != null) {
          onTapOverride!();
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => BookPreview(
                  bookId: bookId,
                  title: title,
                  author: author,
                  description: description,
                  pages: pages,
                  genre: genre,
                  bookImageurl: bookImageurl,
                  shopurl: shopurl,
                  review: review,
                  rating: rating,
                  reviewText: reviewText,
                ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Constants.surface,
          border: Border.all(color: Constants.outline, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 92, height: 132, child: _buildCover()),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Constants.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    author.isEmpty ? "Unknown author" : author,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Constants.mutedInk,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (review)
                    Wrap(
                      spacing: 2,
                      children: List.generate(
                        rating,
                        (index) => const Icon(
                          Icons.star,
                          size: 20,
                          color: Colors.amber,
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (hasPages)
                          _metaPill(
                            Icons.auto_stories_outlined,
                            '$pages pages',
                          ),
                        if (hasGenre) _metaPill(Icons.category_outlined, genre),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Constants.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Constants.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Constants.ink),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Constants.ink,
            ),
          ),
        ],
      ),
    );
  }
}
