import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:testapp3/books/book_provider.dart';
import 'package:testapp3/quiz/quiz_setup.dart';
import 'package:testapp3/main.dart';
import 'package:testapp3/landing.dart';
import 'package:testapp3/books/book.dart';
import 'package:testapp3/books/bookscreen.dart';
import 'package:testapp3/components/reading_cat.dart';
import 'package:testapp3/components/xp_bar.dart';
import 'package:testapp3/login_page.dart';
import 'package:testapp3/util/firebase_utils.dart';
import 'package:testapp3/util/openai_prompt.dart';
import 'package:testapp3/util/profile_avatar_options.dart';

void main() {
  testWidgets(
    'Welcome opens authentication choices without a Firebase dependency',
    (tester) async {
      await tester.pumpWidget(const MyApp(homeOverride: LandingPage()));
      expect(find.text('Welcome to Bookfania'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with email'), findsOneWidget);
    },
  );
  testWidgets('Password reset sends the account email and confirms delivery', (
    tester,
  ) async {
    String? resetEmail;
    await tester.pumpWidget(
      MyApp(
        homeOverride: LoginPage(
          passwordResetSender: (email) async => resetEmail = email,
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email address'),
      'reader@example.com',
    );
    await tester.ensureVisible(find.text('Forgot password?'));
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.text('Reset your password'), findsOneWidget);
    final resetEmailField = find.byType(TextFormField).last;
    expect(resetEmailField, findsOneWidget);
    expect(
      tester.widget<TextFormField>(resetEmailField).controller?.text,
      'reader@example.com',
    );

    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();

    expect(resetEmail, 'reader@example.com');
    expect(find.text('Check your inbox'), findsOneWidget);
    expect(find.text('Return to sign in'), findsOneWidget);
  });
  testWidgets(
    'Post-login library uses the reading companion and clear search',
    (tester) async {
      await tester.pumpWidget(
        const MyApp(
          homeOverride: Scaffold(
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(14, 14, 14, 0),
                child: BookScreen(),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Ready for the next chapter?'), findsOneWidget);
      expect(find.byType(ReadingCat), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  test('Legacy blue cat profiles render with the reading companion', () {
    expect(resolvedProfileAvatar(legacyBlueCatAvatar), defaultProfileAvatar);
  });
  testWidgets('Backup catalog books can start a quiz from the builder', (
    tester,
  ) async {
    final provider =
        BookProvider()..setBook(
          Book.fromOpenLibraryJson({
            'key': '/works/OL27482W',
            'title': 'The Hobbit',
            'author_name': ['J.R.R. Tolkien'],
          }),
        );
    await tester.pumpWidget(
      MyApp(
        homeOverride: ChangeNotifierProvider.value(
          value: provider,
          child: const QuizSetupPage(),
        ),
      ),
    );
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Start Quiz'),
    );
    expect(button.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });
  test('Books preserve volume identity and normalize insecure cover URLs', () {
    final book = Book.fromJson({
      'id': 'volume-123',
      'volumeInfo': {
        'title': 'Book',
        'authors': ['Author'],
        'imageLinks': {'thumbnail': 'http://books.example/cover'},
      },
    });
    expect(book.id, 'volume-123');
    expect(book.thumbnailUrl, 'https://books.example/cover');
    expect(book.authors, ['Author']);
  });
  test('Untrusted quiz responses cannot crash the quiz renderer', () {
    expect(() => OpenaiPrompt.validateQuestions([], 5), throwsException);
    expect(
      () => OpenaiPrompt.validateQuestions([
        {
          'question': 'Q',
          'choices': ['A', 'B'],
        },
      ], 1),
      throwsException,
    );
    expect(
      () => OpenaiPrompt.validateQuestions([
        {
          'question': 'Q',
          'choices': ['A', 'a', 'C', 'D'],
        },
      ], 1),
      throwsException,
    );
    expect(
      OpenaiPrompt.validateQuestions([
        {
          'question': 'Q',
          'choices': ['A', 'B', 'C', 'D'],
          'answer': 0,
        },
      ], 1).first.containsKey('answer'),
      isTrue,
    );
  });
  test('Expired streaks show zero, yesterday and today retain the streak', () {
    final now = DateTime.utc(2026, 9, 7);
    expect(
      FirebaseUtils.activeStreak({
        'streak_count': 8,
        'last_active_date': '2026-09-05',
      }, now: now),
      0,
    );
    expect(
      FirebaseUtils.activeStreak({
        'streak_count': 8,
        'last_active_date': '2026-09-06',
      }, now: now),
      8,
    );
    expect(
      FirebaseUtils.activeStreak({
        'streak_count': 8,
        'last_active_date': '2026-09-07',
      }, now: now),
      8,
    );
  });
  test('Daily and monthly displays reset without requiring a write', () {
    final state = FirebaseUtils.buildQuestState({
      'daily_quest_date': '2026-08-31',
      'daily_quest_progress': {'earn_xp': 20},
      'monthly_quest_month': '2026-08',
      'monthly_quest_progress': 19,
    }, now: DateTime.utc(2026, 9, 1));
    expect((state['dailyQuestProgress'] as Map)['earn_xp'], 0);
    expect(state['monthlyQuestProgress'], 0);
  });
  testWidgets('Leaving during a level-up animation is safe', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: XPBar(
            level: 1,
            xp: 90,
            nextLevelXp: 100,
            targetLevel: 3,
            targetXp: 10,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 810));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
