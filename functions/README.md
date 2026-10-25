# Retained tooling

The app is Cloud-Functions-free. `firebase.json` has no Functions source or emulator,
and Flutter does not call the old API in `src/index.js`. That source and its former
API tests are retained as historical work, not a runtime dependency.

The active test here is `pnpm test:rules`, which uses only local Firestore.
`migrate.js` is an explicit admin operation for existing data; it defaults to a dry
run. See the root README and `docs/RELEASE.md` for the current setup.
