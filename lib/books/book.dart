class Book {
  final String title;
  final List<String> authors;
  final int? pageCount;
  final String? description;
  final String? thumbnailUrl;
  final int? wordcount;
  final String? shopurl;




  Book({
    required this.title,
    required this.authors,
    this.pageCount,
    this.description,
    this.thumbnailUrl,
    this.wordcount,
    this.shopurl
  });
  factory Book.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json["volumeInfo"] ?? {};
    final imageLinks = volumeInfo["imageLinks"] ?? {};
    return Book(
      title: volumeInfo["title"] ?? "Unknown",
      authors: List<String>.from(volumeInfo["authors"] ?? []),
      pageCount: volumeInfo["pageCount"],
      wordcount: (volumeInfo["pageCount"])*300,
      description: volumeInfo["description"],
      thumbnailUrl: imageLinks["thumbnail"],
      shopurl: json["accessInfo"]["webReaderLink"]
    );
  }
}