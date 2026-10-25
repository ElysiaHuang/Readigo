# Audit remediation

> Historical record of the earlier server architecture. It is superseded by the
> Cloud-Functions-free implementation in [README.md](../README.md) and the current
> [release instructions](RELEASE.md). The server dependencies and verification
> claims below describe that earlier revision, not the current app.

The audit led to a coordinated mobile, backend, and Firestore security update.
The new client requires the new backend and migrated data. Follow
[RELEASE.md](RELEASE.md) before distributing it.

## Implemented changes

| Area | Change |
| --- | --- |
| API credentials | Removed client OpenAI SDK and dotenv loading; keys are server secrets. Flutter assets exclude `.env` and the unused badge source sheet. |
| Account ownership | Private UID mappings and server provisioning replace client-controlled account creation. Legacy identities require an explicit administrator migration. |
| Data privacy | Private accounts, libraries, friend lists, and block lists are separated from whitelisted public profiles. Firestore denies access by default. |
| Quiz integrity | The backend verifies the selected Google volume, validates structured questions, keeps answer keys private until submission, and applies per-account generation quotas. |
| XP and quests | Transactions commit attempts, scores, levels, streaks, and daily/monthly quest progress together. Retrying a completed attempt returns the original result. |
| Leagues | UTC week boundaries, immutable weekly scores, deterministic tie breaks, transactional rollover, bounded boards, and actual server-calculated ranks. |
| Authentication | Awaited Google initialization/provisioning, guarded duplicate submits, preserved password whitespace, and central auth-driven navigation. |
| Account deletion | Provider-appropriate reauthentication, recent-login validation, access revocation before cleanup, batched message deletion, and scheduled retry of incomplete cleanup. |
| Chat | Live block enforcement in both UI and rules, bounded message queries, older-message pagination, retained drafts, delivery timeouts, and stable retry IDs. |
| Friends and profiles | Missing/deleted profiles handled, safe error states, bounded search, cached profile loads, validated edits, and best-effort presence updates. |
| Library | Stable book identity, review updates without duplicate counts, legacy deduplication, private pagination, and corrected post-save navigation. |
| UI lifecycle | Mounted checks and disposal for async work, controllers, listeners, timers, and XP animation; stale quest/streak displays refresh. |
| Native builds | iOS minimum target and Google callback configuration corrected. Android release builds require real signing credentials. |
| Repository | Keystore removed from Git's index while retaining the local file; secret/signing ignores, dependency lockfiles, CI checks, and setup/release documentation added. |

## Verification

- Flutter analysis and six regression tests.
- Nine backend domain tests covering validation, scoring, dates, rewards, ranking,
  public-profile filtering, and stable library identity.
- Five Firestore emulator tests covering private access, bounded queries,
  forged writes, chat membership/message validation, blocking, and deletion.
- Nine API emulator tests covering concurrent provisioning, repeated/concurrent
  submissions, authorization, library updates, multi-batch deletion, weekly
  rollover, closed-week submissions, and dry-run/rerunnable legacy migration.
- Android debug compilation and an APK scan confirming the old configured API
  credentials, `.env`, and badge source sheet are absent.
- Unsigned iOS device compilation passed. CocoaPods and the iOS 26.1 runtime
  are installed, and native dependencies are locked in `ios/Podfile.lock`.
- Production dependency vulnerability scan; patched `uuid` and `qs` are pinned
  through the pnpm workspace overrides. Recheck advisories during future releases.

Emulator tests seed quizzes and use dummy secrets. They do not call paid AI or
Google Books APIs. The local emulator used Node 24; deployment and CI target
Node 22. CI must pass on that runtime before release.

## Still requires release operations

Local changes cannot revoke previously distributed credentials or remove copies
of a committed keystore. Rotate/restrict those credentials and resolve signing
identity through the relevant account consoles. Production rules, indexes,
secrets, functions, and the migration have not been applied by this work.

Native OAuth, signed release builds, real-device behavior, and live book/quiz
generation require release smoke tests. AI quiz output is not guaranteed factual;
moderation ownership and a retention policy are also operational requirements.
