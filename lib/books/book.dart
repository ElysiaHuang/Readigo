class Book {
  final String id;
  final String title;
  final List<String> authors;
  final int pageCount;
  final String? description;
  final String genre;
  final String thumbnailUrl;
  final int? wordcount;
  final String shopurl;

  Book({
    this.id = '',
    required this.title,
    required this.authors,
    required this.pageCount,
    this.description,
    required this.genre,
    required this.thumbnailUrl,
    this.wordcount,
    required this.shopurl,
  });

  /// Both catalogs can verify the title and author for quiz generation.
  bool get supportsQuiz => hasQuizBookId(id);

  static bool hasQuizBookId(String value) =>
      hasGoogleVolumeId(value) || hasOpenLibraryWorkId(value);

  static bool hasOpenLibraryWorkId(String value) =>
      RegExp(r'^openlibrary:OL[0-9]+W$').hasMatch(value) && value.length <= 100;

  static bool hasGoogleVolumeId(String value) =>
      RegExp(r'^[A-Za-z0-9_-]{1,100}$').hasMatch(value);

  static String _normalizeUrl(String? rawUrl) {
    final value = rawUrl?.trim() ?? '';
    if (value.isEmpty) return '';
    if (value.startsWith('http://')) {
      return 'https://${value.substring('http://'.length)}';
    }
    return value;
  }

  static List<String> _strings(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? const [] : [trimmed];
    }
    if (value is! Iterable) return const [];
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static int _number(dynamic value) {
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    final rawVolumeInfo = json['volumeInfo'];
    final volumeInfo =
        rawVolumeInfo is Map ? rawVolumeInfo : const <String, dynamic>{};
    final rawAccessInfo = json['accessInfo'];
    final accessInfo =
        rawAccessInfo is Map ? rawAccessInfo : const <String, dynamic>{};
    final rawImageLinks = volumeInfo['imageLinks'];
    final imageLinks =
        rawImageLinks is Map ? rawImageLinks : const <String, dynamic>{};
    final pages = _number(volumeInfo['pageCount']);
    final categories = _strings(volumeInfo['categories']);
    final thumbnail = _normalizeUrl(
      imageLinks['thumbnail']?.toString() ??
          imageLinks['smallThumbnail']?.toString(),
    );
    final previewLink = _normalizeUrl(
      accessInfo['webReaderLink']?.toString() ??
          volumeInfo['previewLink']?.toString() ??
          volumeInfo['infoLink']?.toString() ??
          volumeInfo['canonicalVolumeLink']?.toString(),
    );
    final title = volumeInfo['title']?.toString().trim();
    return Book(
      id: json['id']?.toString() ?? '',
      title: title == null || title.isEmpty ? 'Unknown' : title,
      authors: _strings(volumeInfo['authors']),
      pageCount: pages,
      wordcount: pages > 0 ? pages * 300 : null,
      description: volumeInfo['description']?.toString(),
      genre: categories.isNotEmpty ? categories.first : '',
      thumbnailUrl: thumbnail,
      shopurl: previewLink,
    );
  }

  factory Book.fromOpenLibraryJson(Map<String, dynamic> json) {
    final rawKey = json['key']?.toString() ?? '';
    final workKey = rawKey.replaceFirst(RegExp(r'^/works/'), '').trim();
    final title = json['title']?.toString().trim();
    final subjects = _strings(json['subject']);
    final coverId = _number(json['cover_i']);
    final pages = _number(json['number_of_pages_median']);

    return Book(
      id: 'openlibrary:${workKey.isEmpty ? title ?? 'book' : workKey}',
      title: title == null || title.isEmpty ? 'Unknown' : title,
      authors: _strings(json['author_name']),
      pageCount: pages,
      wordcount: pages > 0 ? pages * 300 : null,
      description: null,
      genre: subjects.isNotEmpty ? subjects.first : '',
      thumbnailUrl:
          coverId > 0
              ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg'
              : '',
      shopurl: rawKey.startsWith('/') ? 'https://openlibrary.org$rawKey' : '',
    );
  }
}
