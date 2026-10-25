# Bookfania

A Flutter reading companion with Google Books search, AI quizzes, private
libraries, friends, chat, quests, and weekly leagues.

## Cloud-Functions-free app

The mobile app uses Firebase Authentication and the Firestore client SDK
directly. Book search calls Google Books, with Open Library as a backup. Quizzes
verify each book's title and author with its original catalog. Development quiz
generation calls OpenAI directly. There is no backend URL, HTTP function,
scheduled function, or Functions deployment in the app configuration.

Firebase's display name is **bookfania**; its project ID is **readigo**
(project number **550818826311**).

## Run

Use Flutter 3.29.3 / Dart 3.7.2 or a compatible newer release. Enable your existing
Firebase Auth providers and Firestore, then deploy these client-access rules:

```sh
firebase deploy --only firestore --project readigo
flutter pub get
flutter run
```

If the database still contains prototype profiles without `accounts/{uid}`
mappings, follow [migration instructions](docs/RELEASE.md) first to retain their
friend codes, reviews, and progress. The app never claims private data by email.

### Development quizzes

The selected direct-key option works only in **debug** builds. Create an ignored
`dev-secrets.json` file locally containing your development credential:

```json
{"OPENAI_API_KEY": "YOUR_DEVELOPMENT_KEY"}
```

```sh
flutter run --dart-define-from-file=dev-secrets.json
```

For local development, `sh scripts/flutter_dev.sh run` and
`sh scripts/flutter_dev.sh apk` always include that file and use debug mode.
The launcher stops if the file is missing, so an artwork rebuild cannot silently
omit the quiz configuration. The old `assets/.env` file is not loaded by the app.

In Android Studio, select the local **Bookfania Development** run configuration.
For another Flutter configuration, set **Additional run args** to
`--debug --dart-define-from-file=dev-secrets.json`. Stop the app and run it again
after changing this setting; hot reload does not add new Dart defines. The local
configuration contains only the secrets-file path, not the key itself.

The development APK launcher creates the normal `app-debug.apk` to keep its
version code consistent with Android Studio's builds and preserve installed data.

Do not commit the file or distribute builds containing this key. Dart defines
do not hide secrets in a compiled app. Profile/release builds reject direct quiz
generation; run their build commands without the secrets file. Other app features
do not need an OpenAI key. No `.env` file or Firebase Secret Manager is loaded.

The API uses [OpenAI structured outputs](https://developers.openai.com/api/docs/guides/structured-outputs)
and validates counts, choices, and answer indices. Questions can still be wrong;
unsupported titles are rejected and readers can report mistakes.

## Regression checks

```sh
flutter analyze --fatal-infos lib test
flutter test
flutter build apk --debug
cd functions
pnpm install --frozen-lockfile
pnpm test:rules
```

The Flutter tests use fake Firestore and mock HTTP responses. The rules suite
uses only a local demo Firestore emulator, with Node.js 22, pnpm 11 and Java 21.
These tests do not change production data or make paid OpenAI calls.

## Data and security model

- `accounts/{uid}` binds the authenticated UID to one immutable friend code.
- `users/{friendCode}` stores the reader's private account, lists, and progress.
- `publicProfiles/{friendCode}` exposes only selected profile and league fields.
- `libraries/{friendCode}/books/{id}` stores private reviews with stable IDs.
- `relationships/{sortedCodes}` stores two participants and their block status.
- `chat/{sortedCodes}/messages/{id}` stores immutable messages; membership,
  blocking and account deletion are checked on reads and writes.
- `quizAttempts/{id}` stores questions, local answer keys, and the owner's result.
  Completed attempts cannot be rewritten. Transaction retries return that result.
- `weeklyScores/{UTC-Monday}/players/{code}` stores self-reported weekly scores.
- `reports` and `reported_content` accept authenticated reports; other readers
  cannot view someone else's reports. Moderation requires an administrator.

Rules enforce ownership, field limits, atomic public/private profile updates,
and private-data boundaries. Quiz scoring, XP, quests and league placement are
client-calculated and **not tamper-proof**. They are suitable for personal reading
progress, not verified competitions. There are no server-enforced API quotas.

Weeks begin on Monday in UTC. Readers update their own league on opening the board
or submitting a quiz; there is no scheduled maintenance. Ranking queries paginate
in groups of 100 and display the top 100 plus the current reader. Their read cost
grows with the league's size. Attempts expire for submission after 24 hours but
are not automatically purged.

Account deletion is performed by the signed-in client and resumes after an
interruption. It deletes private profile/library/quiz data, authored reports and
known conversations, then deletes Firebase Auth. It retains a minimal private UID
mapping and public `{friendCode, deleted: true}` reservation to prevent code reuse.
Historical scores, reports written by others, and their private friend/block
references may remain; see [retention details](docs/RELEASE.md).

`functions/` retains earlier server code and admin migration tooling for reference,
plus the active Firestore rules tests. It is **not deployed or called by the app**.
Its former HTTP API tests are not part of the current model or CI.

The original classroom write-up and earlier audit are historical documents, not
the current architecture specification.
