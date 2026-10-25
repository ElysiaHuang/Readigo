'use strict';
// Run from functions/. Dry run is the default. Uses Application Default Credentials.
const {initializeApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore, FieldValue, Timestamp} = require('firebase-admin/firestore');
const d = require('./src/domain');
const projectId = process.env.GCLOUD_PROJECT;
if (!projectId) throw new Error('Set GCLOUD_PROJECT explicitly.');
initializeApp({projectId});
const db = getFirestore(), auth = getAuth();
async function migrate() {
  const apply = process.argv.includes('--apply');
  const users = await db.collection('users').get();
  const plan = [], owners = new Set();
  // Preflight the entire identity mapping before modifying any record.
  for (const doc of users.docs) {
    const data = doc.data();
    if (!data.email) throw new Error(`Account ${doc.id} has no email; resolve it manually before migration.`);
    const identity = await auth.getUserByEmail(data.email);
    if (owners.has(identity.uid)) throw new Error('Multiple legacy profiles map to one Auth account. Resolve duplicates first.');
    owners.add(identity.uid);
    const mapping = await db.doc(`accounts/${identity.uid}`).get();
    if (data.ownerUid && (data.ownerUid !== identity.uid || !mapping.exists)) throw new Error('Existing ownership is inconsistent. Resolve it before migration.');
    if (mapping.exists && mapping.get('friendCode') !== doc.id) throw new Error('A UID is already bound to another profile. Resolve it first.');
    if (!data.ownerUid) plan.push({ref: doc.ref, uid: identity.uid});
  }
  console.log(`${apply ? 'Applying' : 'Dry run:'} ${plan.length} profiles require migration; ${users.size - plan.length} already migrated.`);
  if (!apply) return;
  for (const {ref, uid} of plan) {
    // Copy library first without changing/deleting legacy data. A rerun uses the
    // same IDs and does not duplicate books, even after an interrupted migration.
    const original = (await ref.get()).data();
    const library = new Map();
    for (const source of original.books ?? []) {
      if (!source || typeof source.title !== 'string') continue;
      const book = {bookId: source.bookId || '', title: source.title, author: source.author || '', imageurl: source.imageurl || '',
        review: source.review || '', rating: Math.max(1, Math.min(5, d.natural(source.rating))), pages: d.natural(source.pages), updatedAt: Timestamp.now()};
      library.set(d.libraryId(book), book);
    }
    for (const [id, book] of library) await db.doc(`libraries/${ref.id}/books/${id}`).set(book);
    await db.runTransaction(async tx => {
      const [snap, mapping] = await Promise.all([tx.get(ref), tx.get(db.doc(`accounts/${uid}`))]);
      if (snap.get('ownerUid')) return;
      if (mapping.exists && mapping.get('friendCode') !== ref.id) throw new Error('Identity mapping changed during migration.');
      const user = snap.data();
      const level = Math.max(1, d.natural(user.level));
      const patch = {ownerUid: uid, friendCode: ref.id, username: user.username || 'Reader', username_lower: (user.username || 'Reader').toLowerCase(),
        level, xp: d.natural(user.xp), next_level_xp: level * 100, books_count: library.size,
        friends: Array.isArray(user.friends) ? user.friends : [], blocked: Array.isArray(user.blocked) ? user.blocked : [],
        league_current_index: Math.min(9, d.natural(user.league_current_index)), league_current_week: d.weekKey(),
        league_weekly_score: user.league_current_week === d.weekKey() ? d.natural(user.league_weekly_score) : 0,
        league_history: Array.isArray(user.league_history) ? user.league_history.slice(0,12) : [], books: FieldValue.delete()};
      tx.update(ref, patch);
      tx.set(db.doc(`accounts/${uid}`), {friendCode: ref.id});
      tx.set(db.doc(`publicProfiles/${ref.id}`), d.publicProfile({...user, ...patch}));
      if (patch.league_weekly_score > 0) tx.set(db.doc(`weeklyScores/${d.weekKey()}/players/${ref.id}`), {score: patch.league_weekly_score, leagueIndex: patch.league_current_index, friendCode: ref.id});
    });
  }
  // Restore existing conversation memberships and both directions of blocking.
  const current = await db.collection('users').get();
  const byCode = new Map(current.docs.map(doc => [doc.id, doc.data()]));
  const pairs = new Set();
  for (const [code, data] of byCode) {
    for (const other of [...(data.friends ?? []), ...(data.blocked ?? [])]) {
      if (other !== code && byCode.has(other)) pairs.add([code, other].sort().join('_'));
    }
  }
  for (const id of pairs) {
    const members = id.split('_');
    const blockedBy = members.filter((code, index) => (byCode.get(code).blocked ?? []).includes(members[1 - index]));
    await db.doc(`relationships/${id}`).set({members, blockedBy});
  }
  console.log('Migration complete. Verify representative accounts before releasing the app.');
}
migrate().catch(error => { console.error(error.message); process.exitCode = 1; });
