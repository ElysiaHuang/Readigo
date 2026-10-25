import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../books/book.dart';
import 'service_exception.dart';

class BookService {
  final http.Client? _client;
  BookService({http.Client? client}) : _client = client;

  final Map<String, List<Book>> _cache = {};

  Future<Map<String, dynamic>> _get(
    Uri uri, {
    required String unavailableMessage,
    required String rateLimitMessage,
  }) async {
    try {
      final response = await (_client == null
              ? http.get(uri)
              : _client.get(uri))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 429) {
        throw ServiceException(rateLimitMessage);
      }
      if (response.statusCode != 200) {
        throw ServiceException(unavailableMessage);
      }
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) throw const FormatException();
      return data;
    } on TimeoutException {
      throw ServiceException(unavailableMessage);
    } on http.ClientException {
      throw ServiceException(unavailableMessage);
    } on FormatException {
      throw ServiceException(unavailableMessage);
    }
  }

  Future<Map<String, dynamic>> getVolume(String id) {
    if (Book.hasOpenLibraryWorkId(id)) return _getOpenLibraryWork(id);
    if (!Book.hasGoogleVolumeId(id)) {
      throw const ServiceException(
        'Choose a book with a valid catalog entry to start a quiz.',
      );
    }
    return _get(
      Uri.https('www.googleapis.com', '/books/v1/volumes/$id'),
      unavailableMessage:
          'Book details are temporarily unavailable. Please retry.',
      rateLimitMessage: 'Book details are busy. Please try again shortly.',
    );
  }

  Future<Map<String, dynamic>> _getOpenLibraryWork(String id) async {
    final workId = id.substring('openlibrary:'.length);
    final work = await _get(
      Uri.https('openlibrary.org', '/works/$workId.json'),
      unavailableMessage:
          'Book details are temporarily unavailable. Please retry.',
      rateLimitMessage: 'Book details are busy. Please try again shortly.',
    );
    final title = work['title'];
    final rawAuthors = work['authors'];
    if (work['key'] != '/works/$workId' ||
        title is! String ||
        title.trim().isEmpty ||
        rawAuthors is! List ||
        rawAuthors.isEmpty ||
        rawAuthors.length > 10) {
      throw const ServiceException(
        'This catalog entry is missing a verified title or author. Try another edition.',
      );
    }
    final names = <String>[];
    // Fetch in sequence to respect the public catalog's request limit.
    for (final entry in rawAuthors) {
      final author = entry is Map ? entry['author'] : null;
      final key = author is Map ? author['key'] : null;
      if (key is! String || !RegExp(r'^/authors/OL[0-9]+A$').hasMatch(key)) {
        throw const ServiceException(
          'This book has no verified author. Try another edition.',
        );
      }
      await Future<void>.delayed(const Duration(seconds: 1));
      final data = await _get(
        Uri.https('openlibrary.org', '$key.json'),
        unavailableMessage:
            'Book author details are temporarily unavailable. Please retry.',
        rateLimitMessage: 'Book details are busy. Please try again shortly.',
      );
      final name = data['name'];
      if (data['key'] != key || name is! String || name.trim().isEmpty) {
        throw const ServiceException(
          'This book has no verified author. Try another edition.',
        );
      }
      names.add(name.trim());
    }
    return {
      'id': id,
      'volumeInfo': {'title': title.trim(), 'authors': names},
    };
  }

  Future<List<Book>> searchBooks(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];
    if (trimmed.length > 200) {
      throw const ServiceException('Please use a shorter search.');
    }

    final key = trimmed.toLowerCase();
    final cached = _cache[key];
    if (cached != null) return cached;

    List<Book> books;
    try {
      books = await _searchGoogleBooks(trimmed);
    } on ServiceException {
      books = await _searchOpenLibrary(trimmed);
    }

    if (_cache.length >= 30) _cache.remove(_cache.keys.first);
    _cache[key] = books;
    return books;
  }

  Future<List<Book>> _searchGoogleBooks(String query) async {
    final data = await _get(
      Uri.https('www.googleapis.com', '/books/v1/volumes', {
        'q': query,
        'maxResults': '20',
        'printType': 'books',
      }),
      unavailableMessage: 'Google Books is temporarily unavailable.',
      rateLimitMessage: 'Google Books is busy.',
    );
    return _googleBooks(data);
  }

  Future<List<Book>> _searchOpenLibrary(String query) async {
    final data = await _get(
      Uri.https('openlibrary.org', '/search.json', {
        'q': query,
        'limit': '20',
        'fields':
            'key,title,author_name,number_of_pages_median,cover_i,subject',
      }),
      unavailableMessage:
          'Book search is temporarily unavailable. Please try again shortly.',
      rateLimitMessage: 'Book search is busy. Please try again shortly.',
    );
    final rawDocs = data['docs'];
    if (rawDocs is! List) {
      throw const ServiceException('Book search returned invalid results.');
    }
    return rawDocs
        .whereType<Map<String, dynamic>>()
        .map((item) {
          try {
            return Book.fromOpenLibraryJson(item);
          } catch (_) {
            return null;
          }
        })
        .whereType<Book>()
        .toList();
  }

  List<Book> _googleBooks(Map<String, dynamic> data) {
    final rawItems = data['items'];
    if (rawItems != null && rawItems is! List) {
      throw const ServiceException(
        'Google Books returned invalid search results.',
      );
    }
    return (rawItems as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((item) {
          try {
            return Book.fromJson(item);
          } catch (_) {
            return null;
          }
        })
        .whereType<Book>()
        .toList();
  }
}
