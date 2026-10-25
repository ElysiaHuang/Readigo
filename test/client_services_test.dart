import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:testapp3/util/book_service.dart';
import 'package:testapp3/util/firestore_service.dart';
import 'package:testapp3/util/openai_prompt.dart';
import 'package:testapp3/util/profile_avatar_options.dart';
import 'package:testapp3/util/reading_progress.dart';
import 'package:testapp3/util/service_exception.dart';

List<Map<String, dynamic>> questions([int count = 5]) => List.generate(
  count,
  (i) => {
    'question': 'Question $i',
    'choices': ['A', 'B', 'C', 'D'],
    'answer': i % 4,
  },
);
Map<String, dynamic> quiz() => {
  'bookId': 'volume',
  'title': 'Book',
  'authors': ['Author'],
  'count': 5,
  'difficulty': 2,
  'chapterScope': '',
  'questions': questions(),
};

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreService alice, bob;
  late String a, b;
  setUp(() async {
    db = FakeFirebaseFirestore();
    alice = FirestoreService(db, 'alice');
    bob = FirestoreService(db, 'bob');
    a = await alice.provision(
      'Alice',
      'alice@example.com',
      defaultProfileAvatar,
    );
    b = await bob.provision('Bob', 'bob@example.com', defaultProfileAvatar);
  });

  test(
    'startup provisions once and preserves the existing account on retry',
    () async {
      final again = await alice.provision(
        'New Name',
        'alice@example.com',
        defaultProfileAvatar,
      );
      expect(again, a);
      expect((await alice.user(a).get()).data()!['username'], 'Alice');
      expect((await db.collection('users').get()).docs, hasLength(2));
    },
  );
  test(
    'profile updates project only public fields and reject ownership edits',
    () async {
      await alice.updateProfile(a, {
        'username': 'Alice Reader',
        'bio': 'Reading',
      });
      final profile = (await alice.profile(a).get()).data()!;
      expect(profile['username_lower'], 'alice reader');
      expect(profile.containsKey('email'), false);
      expect(profile.containsKey('ownerUid'), false);
      await expectLater(
        alice.updateProfile(a, {'ownerUid': 'bob'}),
        throwsException,
      );
    },
  );
  test(
    'library retries and legacy review consolidation preserve one count',
    () async {
      final book = {
        'bookId': '',
        'title': 'Book',
        'author': 'Author',
        'imageurl': '',
        'pages': 100,
        'rating': 4,
        'review': 'Good',
      };
      await alice.saveBook(book);
      await alice.saveBook({...book, 'bookId': 'volume'});
      await alice.saveBook({...book, 'bookId': 'volume', 'rating': 5});
      expect(
        (await db.collection('libraries').doc(a).collection('books').get())
            .docs,
        hasLength(1),
      );
      expect((await alice.user(a).get()).data()!['books_count'], 1);
      expect((await alice.profile(a).get()).data()!['books_count'], 1);
    },
  );
  test(
    'friend, block and unblock flow preserves the other reader’s block',
    () async {
      await alice.relationship(b, friend: true);
      expect((await alice.user(a).get()).data()!['friends'], [b]);
      await alice.relationship(b, block: true);
      expect((await alice.user(a).get()).data()!['friends'], isEmpty);
      await bob.relationship(a, block: true);
      final state = await alice.relationship(b, block: false);
      expect(state, {'blockedByMe': false, 'blockedByFriend': true});
      await expectLater(alice.relationship(b, friend: true), throwsException);
    },
  );
  test(
    'quiz submit, duplicate submit and reports use the actual direct client',
    () async {
      final id = await alice.saveQuiz(quiz());
      final result = await alice.submitQuiz(id, [0, 1, 2, 3, 0]);
      expect(result['correctCount'], 5);
      expect(result['gainedXp'], 10);
      expect(await alice.submitQuiz(id, [1, 1, 1, 1, 1]), result);
      final me = (await alice.user(a).get()).data()!;
      expect(me['xp'], 10);
      expect(me['league_weekly_score'], 10);
      expect(me['daily_quest_progress']['finish_quizzes'], 1);
      await alice.reportQuiz(id, 0, 'Wrong answer');
      expect(
        (await db.collection('reported_content').doc('${id}_0').get())
            .data()!['question'],
        questions()[0],
      );
      await expectLater(bob.submitQuiz(id, [0, 1, 2, 3, 0]), throwsException);
    },
  );
  test('incomplete or expired attempts never award progress', () async {
    final id = await alice.saveQuiz(quiz());
    await expectLater(alice.submitQuiz(id, [-1, 1, 2, 3, 0]), throwsException);
    await db.collection('quizAttempts').doc(id).update({
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 2)),
      ),
    });
    await expectLater(alice.submitQuiz(id, [0, 1, 2, 3, 0]), throwsException);
    expect((await alice.user(a).get()).data()!['xp'], 0);
  });
  test('weekly rollover promotes once and records history', () async {
    final old = ReadingProgress.weekKey(
      DateTime.now().subtract(const Duration(days: 7)),
    );
    await alice.user(a).update({
      'league_current_week': old,
      'league_weekly_score': 10,
    });
    await alice.profile(a).update({
      'league_current_week': old,
      'league_weekly_score': 10,
    });
    await db
        .collection('weeklyScores')
        .doc(old)
        .collection('players')
        .doc(a)
        .set({'friendCode': a, 'leagueIndex': 0, 'score': 10});
    await alice.syncLeague(a);
    await alice.syncLeague(a);
    final me = (await alice.user(a).get()).data()!;
    expect(me['league_current_index'], 1);
    expect(me['league_weekly_score'], 0);
    expect(me['league_history'], hasLength(1));
    expect(
      (await alice.leaderboard()).any((row) => row['friendCode'] == a),
      true,
    );
  });
  test('deletion retries remove owned data while reserving the code', () async {
    await alice.relationship(b, friend: true);
    final chat = ([a, b]..sort()).join('_');
    await db.collection('chat').doc(chat).collection('messages').add({
      'text': 'Hello',
    });
    await alice.saveQuiz(quiz());
    await alice.reportUser(b, 'Spam');
    await alice.deleteData(a);
    await alice.deleteData(a);
    expect((await alice.user(a).get()).exists, false);
    expect((await alice.profile(a).get()).data(), {
      'friendCode': a,
      'deleted': true,
    });
    expect((await alice.account.get()).data()!['deleting'], true);
    expect((await db.collection('quizAttempts').get()).docs, isEmpty);
    expect(
      (await db.collection('chat').doc(chat).collection('messages').get()).docs,
      isEmpty,
    );
    expect((await bob.user(b).get()).exists, true);
  });
  test(
    'direct Google Books search escapes queries, caches results and needs no auth',
    () async {
      var calls = 0;
      final service = BookService(
        client: MockClient((request) async {
          calls++;
          expect(request.url.host, 'www.googleapis.com');
          expect(request.url.queryParameters['q'], 'A & B');
          expect(request.headers.containsKey('Authorization'), false);
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'id': 'volume',
                  'volumeInfo': {'title': 'Book'},
                },
              ],
            }),
            200,
          );
        }),
      );
      expect((await service.searchBooks(' A & B ')).single.id, 'volume');
      await service.searchBooks('A & B');
      expect(calls, 1);
    },
  );
  test(
    'book search falls back to Open Library when Google Books is rate-limited',
    () async {
      final hosts = <String>[];
      final service = BookService(
        client: MockClient((request) async {
          hosts.add(request.url.host);
          if (request.url.host == 'www.googleapis.com') {
            return http.Response('', 429);
          }
          expect(request.url.host, 'openlibrary.org');
          expect(request.url.queryParameters['q'], 'The Hobbit');
          return http.Response(
            jsonEncode({
              'docs': [
                {
                  'key': '/works/OL27482W',
                  'title': 'The Hobbit',
                  'author_name': ['J. R. R. Tolkien'],
                  'number_of_pages_median': 310,
                  'cover_i': 14627509,
                  'subject': ['Fantasy'],
                },
              ],
            }),
            200,
          );
        }),
      );

      final book = (await service.searchBooks('The Hobbit')).single;
      expect(hosts, ['www.googleapis.com', 'openlibrary.org']);
      expect(book.id, 'openlibrary:OL27482W');
      expect(book.thumbnailUrl, contains('covers.openlibrary.org'));
      expect(book.supportsQuiz, true);
    },
  );
  test(
    'book provider failures are not cached after both catalogs fail',
    () async {
      var calls = 0;
      final service = BookService(
        client: MockClient((_) async {
          calls++;
          return http.Response('<html>down</html>', 503);
        }),
      );
      for (var i = 0; i < 2; i++) {
        await expectLater(service.searchBooks('Book'), throwsException);
      }
      expect(calls, 4);
    },
  );
  test(
    'direct quiz API uses book identity and returns validated local answers',
    () async {
      final calls = <String>[];
      final api = DirectQuizApi(
        apiKey: 'test-key',
        client: MockClient((request) async {
          calls.add(request.url.host);
          if (request.url.host == 'www.googleapis.com') {
            return http.Response(
              jsonEncode({
                'volumeInfo': {
                  'title': 'Book',
                  'authors': ['Author'],
                },
              }),
              200,
            );
          }
          expect(request.url.path, '/v1/chat/completions');
          expect(request.headers['Authorization'], 'Bearer test-key');
          final body = jsonDecode(request.body);
          expect(body['store'], false);
          expect(body['response_format']['json_schema']['strict'], true);
          expect(jsonDecode(body['messages'][1]['content'])['authors'], [
            'Author',
          ]);
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'finish_reason': 'stop',
                  'message': {
                    'content': jsonEncode({
                      'supported': true,
                      'questions': questions(),
                    }),
                  },
                },
              ],
            }),
            200,
          );
        }),
      );
      expect((await api.generate(5, 'volume', 2))['questions'], questions());
      expect(calls, ['www.googleapis.com', 'api.openai.com']);
    },
  );
  test(
    'expert quizzes require the selected count and 25 questions save and score',
    () async {
      for (final count in [5, 10, 15, 20, 25]) {
        final api = DirectQuizApi(
          apiKey: 'test-key',
          client: MockClient((request) async {
            if (request.url.host == 'www.googleapis.com') {
              return http.Response(
                jsonEncode({
                  'volumeInfo': {
                    'title': 'Book',
                    'authors': ['Author'],
                  },
                }),
                200,
              );
            }
            final body = jsonDecode(request.body);
            final schema = body['response_format']['json_schema']['schema'];
            final questionSchema = schema['properties']['questions'];
            expect(questionSchema['type'], ['array', 'null']);
            expect(questionSchema['minItems'], count);
            expect(questionSchema['maxItems'], count);
            final item = questionSchema['items']['properties'];
            expect(item['choices']['minItems'], 4);
            expect(item['choices']['maxItems'], 4);
            expect(item['answer']['enum'], [0, 1, 2, 3]);
            expect(body['messages'][0]['content'], contains('exactly $count'));
            expect(body['messages'][0]['content'], contains('Expert mode'));
            final input = jsonDecode(body['messages'][1]['content']);
            expect(input['count'], count);
            expect(input['difficulty'], 12);
            if (count == 25) expect(body['max_tokens'], greaterThan(8000));
            return http.Response(
              jsonEncode({
                'choices': [
                  {
                    'finish_reason': 'stop',
                    'message': {
                      'content': jsonEncode({
                        'supported': true,
                        'questions': questions(count),
                      }),
                    },
                  },
                ],
              }),
              200,
            );
          }),
        );
        final generated = await api.generate(count, 'volume', 12);
        expect(generated['questions'], hasLength(count));
        expect(generated['count'], count);
        expect(generated['difficulty'], 12);
        if (count == 25) {
          final id = await alice.saveQuiz(generated);
          final answers = questions(25).map((q) => q['answer'] as int).toList();
          final result = await alice.submitQuiz(id, answers);
          expect(result['correctCount'], 25);
          expect(result['gainedXp'], 300);
          expect(await alice.submitQuiz(id, answers), result);
        }
      }
    },
  );
  test(
    'expert quizzes refuse unsupported books and truncated output safely',
    () async {
      for (final truncated in [false, true]) {
        var aiCalls = 0;
        final api = DirectQuizApi(
          apiKey: 'test-key',
          client: MockClient((request) async {
            if (request.url.host == 'www.googleapis.com') {
              return http.Response(
                jsonEncode({
                  'volumeInfo': {'title': 'Book'},
                }),
                200,
              );
            }
            aiCalls++;
            return http.Response(
              jsonEncode({
                'choices': [
                  {
                    'finish_reason': truncated ? 'length' : 'stop',
                    'message': {
                      'content':
                          truncated
                              ? '{"supported":true,"questions":['
                              : jsonEncode({
                                'supported': false,
                                'questions': null,
                              }),
                    },
                  },
                ],
              }),
              200,
            );
          }),
        );
        await expectLater(
          api.generate(25, 'volume', 12),
          throwsA(
            isA<ServiceException>().having(
              (e) => e.message,
              'message',
              contains(
                truncated ? 'stopped before it finished' : 'Try another book',
              ),
            ),
          ),
        );
        expect(aiCalls, 1);
        expect((await db.collection('quizAttempts').get()).docs, isEmpty);
      }
    },
  );
  test('25-question quizzes still reject short or duplicate responses', () {
    expect(
      () => OpenaiPrompt.validateQuestions(questions(24), 25),
      throwsException,
    );
    final duplicate = questions(25);
    duplicate[24] = duplicate[0];
    expect(
      () => OpenaiPrompt.validateQuestions(duplicate, 25),
      throwsException,
    );
  });
  test(
    'backup catalog quiz verifies work and author, then saves and scores normally',
    () async {
      final requests = <String>[];
      final api = DirectQuizApi(
        apiKey: 'test-key',
        client: MockClient((request) async {
          requests.add('${request.url.host}${request.url.path}');
          if (request.url.path == '/works/OL27482W.json') {
            return http.Response(
              jsonEncode({
                'key': '/works/OL27482W',
                'title': 'The Hobbit',
                'authors': [
                  {
                    'author': {'key': '/authors/OL26320A'},
                  },
                ],
              }),
              200,
            );
          }
          if (request.url.path == '/authors/OL26320A.json') {
            return http.Response(
              jsonEncode({
                'key': '/authors/OL26320A',
                'name': 'J.R.R. Tolkien',
              }),
              200,
            );
          }
          expect(request.url.host, 'api.openai.com');
          final input = jsonDecode(
            jsonDecode(request.body)['messages'][1]['content'],
          );
          expect(input['title'], 'The Hobbit');
          expect(input['authors'], ['J.R.R. Tolkien']);
          expect(input['bookId'], 'openlibrary:OL27482W');
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'finish_reason': 'stop',
                  'message': {
                    'content': jsonEncode({
                      'supported': true,
                      'questions': questions(),
                    }),
                  },
                },
              ],
            }),
            200,
          );
        }),
      );
      final generated = await api.generate(5, 'openlibrary:OL27482W', 2);
      final id = await alice.saveQuiz(generated);
      final result = await alice.submitQuiz(id, [0, 1, 2, 3, 0]);
      expect(result['correctCount'], 5);
      expect(result['gainedXp'], 10);
      expect(requests, [
        'openlibrary.org/works/OL27482W.json',
        'openlibrary.org/authors/OL26320A.json',
        'api.openai.com/v1/chat/completions',
      ]);
    },
  );
  test(
    'backup catalog entries without verified authors never call AI',
    () async {
      var calls = 0;
      final api = DirectQuizApi(
        apiKey: 'test-key',
        client: MockClient((request) async {
          calls++;
          expect(request.url.host, 'openlibrary.org');
          return http.Response(
            jsonEncode({
              'key': '/works/OL27482W',
              'title': 'The Hobbit',
              'authors': [],
            }),
            200,
          );
        }),
      );
      await expectLater(
        api.generate(5, 'openlibrary:OL27482W', 2),
        throwsException,
      );
      expect(calls, 1);
      await expectLater(
        api.generate(5, 'openlibrary:../../evil', 2),
        throwsException,
      );
      expect(calls, 1);
    },
  );
  test(
    'quiz 429 errors distinguish billing, usage, and temporary throttling',
    () async {
      final cases = <String, String>{
        'credit_balance_exhausted': 'no credits left',
        'project_spend_limit_exceeded': 'project’s spending limit',
        'organization_spend_limit_exceeded': 'account’s spending limit',
        'organization_usage_limit_exceeded': 'usage allowance',
        'insufficient_quota': 'retrying alone will not fix this',
        'billing_hard_limit_reached': 'retrying alone will not fix this',
        'rate_limit_exceeded': 'temporarily rate-limited',
        'slow_down': 'temporarily rate-limited',
      };
      for (final entry in cases.entries) {
        var aiCalls = 0;
        final api = DirectQuizApi(
          apiKey: 'test-key',
          client: MockClient((request) async {
            if (request.url.host == 'www.googleapis.com') {
              return http.Response(
                jsonEncode({
                  'volumeInfo': {'title': 'Book'},
                }),
                200,
              );
            }
            aiCalls++;
            return http.Response(
              jsonEncode({
                'error': {
                  'code': entry.key,
                  'type': 'insufficient_quota',
                  'message': 'Private provider payload',
                },
              }),
              429,
            );
          }),
        );
        await expectLater(
          api.generate(5, 'volume', 2),
          throwsA(
            isA<ServiceException>().having(
              (e) => e.message,
              'actionable message',
              allOf(
                contains(entry.value),
                isNot(contains('Private provider payload')),
              ),
            ),
          ),
        );
        expect(
          aiCalls,
          1,
          reason: 'Do not automatically retry quota failures.',
        );
      }
    },
  );
  test(
    'unknown and malformed 429 responses do not guess a billing cause',
    () async {
      for (final body in [
        '<html>gateway failure</html>',
        jsonEncode({
          'error': {'code': 'unknown', 'message': 'private'},
        }),
      ]) {
        final api = DirectQuizApi(
          apiKey: 'test-key',
          client: MockClient((request) async {
            if (request.url.host == 'www.googleapis.com') {
              return http.Response(
                jsonEncode({
                  'volumeInfo': {'title': 'Book'},
                }),
                200,
              );
            }
            return http.Response(body, 429);
          }),
        );
        await expectLater(
          api.generate(5, 'volume', 2),
          throwsA(
            isA<ServiceException>().having(
              (e) => e.message,
              'message',
              contains('identify the cause'),
            ),
          ),
        );
      }
    },
  );
  test(
    'direct quizzes reject missing config, production mode, and invalid answer keys',
    () {
      expect(() => OpenaiPrompt.ensureConfigured(apiKey: ''), throwsException);
      expect(
        () => OpenaiPrompt.ensureConfigured(debug: false, apiKey: 'key'),
        throwsException,
      );
      expect(
        () => OpenaiPrompt.validateQuestions([
          {...questions()[0], 'answer': 4},
        ], 1),
        throwsException,
      );
      expect(
        () =>
            OpenaiPrompt.validateQuestions([questions()[0], questions()[0]], 2),
        throwsException,
      );
    },
  );
  test(
    'quest and level boundaries retain earned badges and reset daily progress',
    () {
      final result = ReadingProgress.rewardState(
        {
          'xp': 95,
          'level': 1,
          'daily_quest_date': '2026-09-12',
          'daily_quest_progress': {'earn_xp': 19},
          'monthly_quest_month': '2026-09',
          'monthly_quest_progress': 19,
        },
        10,
        5,
        DateTime.utc(2026, 9, 12),
      );
      expect(result['level'], 2);
      expect(result['xp'], 5);
      expect(result['monthly_quest_progress'], 20);
      expect(result['monthly_badges'], hasLength(1));
      final tomorrow = ReadingProgress.rewardState(
        result,
        2,
        1,
        DateTime.utc(2026, 9, 13),
      );
      expect(tomorrow['daily_quest_progress']['earn_xp'], 2);
      expect(tomorrow['monthly_badges'], hasLength(1));
      expect(
        ReadingProgress.weekKey(DateTime.utc(2026, 9, 13, 23, 59)),
        '2026-09-07',
      );
      expect(ReadingProgress.weekKey(DateTime.utc(2026, 9, 14)), '2026-09-14');
    },
  );
}
