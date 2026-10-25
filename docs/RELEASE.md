# Cloud-Functions-free setup and release

## Firebase configuration

Keep the existing **bookfania** Firebase project, ID **readigo**, number
**550818826311**. Firebase Auth and Firestore are the app's Firebase services.
The app no longer uses an HTTP backend or Functions secrets.

Deploy the matching rules and indexes before testing against the live project:

```sh
firebase deploy --only firestore --project readigo
```

This command changes live Firestore access rules. Local regression tests do not
deploy anything. Use a staging database and a backup before changing access to an
existing production database. Never use unrestricted allow-all rules to unblock
startup. Rules permission errors after this upgrade usually mean the new rules
have not been deployed, or the existing data needs the migration below.

## Existing data

Accounts created under the previous server architecture already have a UID
mapping, a private profile, and a public projection. Their IDs and library hashes
are retained. Existing weekly scores can acquire time-window fields when written
during their current week; older weeks cannot be reopened.

Prototype records that lack an `accounts/{uid}` mapping require an administrator
to bind the existing Auth UID before allowing this app to provision new profiles.
Do not derive ownership from a client-supplied email address. Back up Firestore
and Auth first and stop old-client writes during migration.

The retained admin script is run locally using Application Default Credentials;
it does not need Cloud Functions. From `functions/`:

```sh
GCLOUD_PROJECT=readigo node migrate.js
# Review the dry run and backup before applying:
GCLOUD_PROJECT=readigo node migrate.js --apply
```

Verify representative profiles against the current rule schema, especially
avatars, complete quest defaults, unknown legacy fields, and UID ownership.
Resolve duplicate or unmatched identities before releasing; never let the app
create a second profile to work around a missing mapping.

## Direct OpenAI development option

Use the ignored `dev-secrets.json` and debug command in the README. A key embedded
in any mobile build can be extracted. Only use a development key and keep the
build private. Revoke any previously distributed key. No new key has been created
or configured by the code changes.

Profile and release builds deliberately reject direct OpenAI generation. All
other features remain available. Build release artifacts without the secrets
file. Direct quizzes are not a production credential-storage solution.

## Behavior and retention

- Private data stays owner-only; public profiles deliberately share reading
  statistics and presence. Scores and quiz answers are controlled by the client.
- Quizzes update progress atomically, and resubmitting a completed attempt reads
  its saved result. This prevents accidental double rewards, not deliberate cheating.
- Daily and weekly boundaries use UTC. League movement runs for the current reader
  when the app is used. There is no automatic rollover for inactive accounts and
  no maintenance function, automatic expired-attempt deletion, or daily API quota.
- Account deletion starts after UI reauthentication. The client marks the account
  as deleting, which blocks further writes and conversations, cleans data in pages,
  and deletes Auth last. If interrupted, sign in again to resume. There is no
  background deletion worker; the app must stay connected until it finishes.
- Minimal UID/code tombstones reserve the old identity. Anonymous historical
  weekly scores, reports filed by other readers, and codes in other readers'
  private friend/block lists remain. Administrators must handle broader retention
  or erasure needs and orphaned legacy conversations without relationship records.
- Moderation reports require review in an admin tool or console. This repository
  does not supply a moderation console or scheduled retention process.

## Validation and signing

Run the README's Flutter and emulator checks. Smoke-test Google/email sign-in,
startup, book search, profile editing, review edits, quiz generation and repeated
submission, blocking while chat is open, and account deletion with two test users.
Passing local tests does not prove that live rules, OAuth, API quotas, or native
signing are configured correctly.

Create ignored `android/key.properties` from its example before an Android release.
The earlier committed signing key and OpenAI credential should be reviewed and
rotated as appropriate; deleting files does not invalidate old copies. Do not
replace an existing app-signing identity without checking the store configuration.
iOS OAuth, device behavior and App Store signing need a device/Xcode check.
