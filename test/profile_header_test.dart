import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp3/profile/profile_header.dart';

void main() {
  const friendCode = 'C4FSZFKGE5CN';
  for (final width in [320.0, 390.0, 600.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Other profile fits at width $width and text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var copies = 0;
        var friendActions = 0;
        var moreActions = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: SingleChildScrollView(
                  // Matches the page, profile, and card's combined padding.
                  child: Padding(
                    padding: const EdgeInsets.all(42),
                    child: ProfileHeader(
                      username: 'Glitch tam with a very long display name',
                      friendCode: friendCode,
                      avatar: const AssetImage('assets/images/reading_cat.png'),
                      onCopy: () => copies++,
                      primaryAction: IconButton(
                        onPressed: () => friendActions++,
                        tooltip: 'Add friend',
                        icon: const Icon(Icons.person_add),
                      ),
                      moreAction: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                        ),
                        child: IconButton(
                          onPressed: () => moreActions++,
                          tooltip: 'More actions',
                          icon: const Icon(Icons.more_vert),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        for (final finder in [
          find.text(friendCode),
          find.byTooltip('Copy friend code'),
          find.byTooltip('Add friend'),
          find.byTooltip('More actions'),
        ]) {
          final bounds = tester.getRect(finder);
          expect(bounds.left, greaterThanOrEqualTo(42));
          expect(bounds.right, lessThanOrEqualTo(width - 42));
        }
        await tester.tap(find.byTooltip('Copy friend code'));
        await tester.tap(find.byTooltip('Add friend'));
        await tester.tap(find.byTooltip('More actions'));
        expect(copies, 1);
        expect(friendActions, 1);
        expect(moreActions, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Own profile keeps edit and copy actions accessible', (
    tester,
  ) async {
    var edits = 0;
    var copies = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 236,
            child: ProfileHeader(
              username: 'Reader',
              friendCode: friendCode,
              avatar: const AssetImage('assets/images/reading_cat.png'),
              onCopy: () => copies++,
              primaryAction: IconButton(
                onPressed: () => edits++,
                tooltip: 'Edit profile',
                icon: const Icon(Icons.settings),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Copy friend code'));
    await tester.tap(find.byTooltip('Edit profile'));
    expect(copies, 1);
    expect(edits, 1);
    expect(tester.takeException(), isNull);
  });
}
