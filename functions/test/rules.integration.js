'use strict';
const {test, before, after, beforeEach} = require('node:test');
const assert = require('node:assert/strict');
const {readFileSync} = require('node:fs');
const {initializeTestEnvironment, assertFails, assertSucceeds} = require('@firebase/rules-unit-testing');
const {doc, setDoc, getDoc, updateDoc, deleteDoc, getDocs, collection, query, where, limit,
  serverTimestamp, writeBatch, runTransaction, Timestamp, setLogLevel} = require('firebase/firestore');
const {publicProfile, weekKey, rewardState} = require('../src/domain');
let env;
const userData = (uid, code) => ({ownerUid: uid, email: `${uid}@example.com`, username: uid,
  username_lower: uid, bio: '', profilePic: 'assets/images/avatars/cat.png', friendCode: code,
  dateCreated: serverTimestamp(), level: 1, xp: 0, next_level_xp: 100, books_count: 0,
  friends: [], blocked: [], streak_count: 0, last_active_date: '', activity_dates: [],
  daily_quest_date: '', daily_quest_progress: {}, monthly_quest_month: '2026-09',
  monthly_quest_progress: 0, monthly_badges: [], league_current_index: 0,
  league_current_week: weekKey(), league_weekly_score: 0, league_history: []});
const client = uid => env.authenticatedContext(uid, {email: `${uid}@example.com`}).firestore();
async function provision(db, uid, code) {
  return runTransaction(db, async tx => {
    const mapping = await tx.get(doc(db, 'accounts', uid));
    if (mapping.exists()) return mapping.data().friendCode;
    if ((await tx.get(doc(db, 'publicProfiles', code))).exists()) return null;
    const data = userData(uid, code);
    tx.set(doc(db, 'accounts', uid), {friendCode: code});
    tx.set(doc(db, 'users', code), data);
    tx.set(doc(db, 'publicProfiles', code), publicProfile(data));
    return code;
  });
}
async function block(db, code, other, blockedBy) {
  const batch = writeBatch(db);
  batch.update(doc(db, 'users', code), {blocked: blockedBy.includes(code) ? [other] : []});
  batch.update(doc(db, 'relationships', [code, other].sort().join('_')), {blockedBy});
  return batch.commit();
}
const message = () => ({senderId: 'AAAAA', receiverId: 'BBBBB', text: 'Hello', timestamp: serverTimestamp()});
const quiz = uid => ({uid, friendCode: 'AAAAA', bookId: 'volume', title: 'Book', authors: ['Author'],
  count: 5, difficulty: 2, chapterScope: '', createdAt: serverTimestamp(), completed: false,
  questions: Array.from({length: 5}, (_, i) => ({question: `Q${i}`, choices: ['A', 'B', 'C', 'D'], answer: 0}))});
before(async () => {
  setLogLevel('silent'); // Expected denials are assertions, not test failures.
  env = await initializeTestEnvironment({projectId: 'demo-bookfania-rules', firestore: {rules: readFileSync('../firestore.rules', 'utf8')}});
});
after(async () => { await env?.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    for (const [uid, code] of [['alice', 'AAAAA'], ['bob', 'BBBBB']]) {
      const data = userData(uid, code);
      await setDoc(doc(db, 'accounts', uid), {friendCode: code});
      await setDoc(doc(db, 'users', code), data);
      await setDoc(doc(db, 'publicProfiles', code), publicProfile(data));
    }
    await setDoc(doc(db, 'relationships', 'AAAAA_BBBBB'), {members: ['AAAAA', 'BBBBB'], blockedBy: []});
  });
});
test('direct provisioning is atomic and simultaneous startup calls reuse one mapping', async () => {
  const db = client('charlie');
  const results = await Promise.all([provision(db, 'charlie', 'CCCCC'), provision(db, 'charlie', 'DDDDD')]);
  assert.equal(results[0], results[1]);
  assert.equal((await getDoc(doc(db, 'users', results[0]))).data().ownerUid, 'charlie');
  assert.equal((await getDoc(doc(db, 'publicProfiles', results[0]))).data().username, 'charlie');
});
test('provisioning cannot claim another identity, overwrite a mapping or create partial records', async () => {
  const db = client('charlie');
  await assertFails(setDoc(doc(db, 'accounts', 'alice'), {friendCode: 'CCCCC'}));
  await assertFails(setDoc(doc(db, 'accounts', 'charlie'), {friendCode: 'AAAAA'}));
  await assertFails(setDoc(doc(db, 'accounts', 'charlie'), {friendCode: 'CCCCC'}));
  await assertFails(setDoc(doc(db, 'users', 'CCCCC'), userData('charlie', 'CCCCC')));
  await assertFails(updateDoc(doc(client('alice'), 'accounts', 'alice'), {friendCode: 'BBBBB'}));
  const batch = writeBatch(db);
  const data = {...userData('charlie', 'CCCCC'), email: 'alice@example.com'};
  batch.set(doc(db, 'accounts', 'charlie'), {friendCode: 'CCCCC'});
  batch.set(doc(db, 'users', 'CCCCC'), data);
  batch.set(doc(db, 'publicProfiles', 'CCCCC'), publicProfile(data));
  await assertFails(batch.commit());
});
test('private records remain private and public queries stay bounded', async () => {
  const db = client('alice');
  await assertSucceeds(getDoc(doc(db, 'users', 'AAAAA')));
  await assertFails(getDoc(doc(db, 'users', 'BBBBB')));
  await assertFails(getDoc(doc(db, 'accounts', 'bob')));
  await assertFails(getDocs(collection(db, 'users')));
  await assertFails(getDoc(doc(db, 'libraries', 'BBBBB', 'books', 'one')));
  await assertSucceeds(getDocs(query(collection(db, 'publicProfiles'), limit(30))));
  await assertFails(getDocs(collection(db, 'publicProfiles')));
  await assertFails(getDocs(query(collection(env.unauthenticatedContext().firestore(), 'publicProfiles'), limit(30))));
});
test('profile and self-reported progress update together without exposing private fields', async () => {
  const db = client('alice');
  const batch = writeBatch(db);
  const patch = {username: 'Alice Reader', username_lower: 'alice reader', xp: 30};
  batch.update(doc(db, 'users', 'AAAAA'), patch);
  batch.update(doc(db, 'publicProfiles', 'AAAAA'), patch);
  await assertSucceeds(batch.commit());
  await assertFails(updateDoc(doc(db, 'publicProfiles', 'AAAAA'), {email: 'private@example.com'}));
  await assertFails(updateDoc(doc(db, 'users', 'AAAAA'), {ownerUid: 'bob'}));
  await assertFails(updateDoc(doc(db, 'users', 'AAAAA'), {xp: 99}));
  await assertFails(updateDoc(doc(db, 'publicProfiles', 'AAAAA'), {xp: 99}));
  await assertFails(updateDoc(doc(db, 'publicProfiles', 'BBBBB'), {username: 'Stolen'}));
  await assertSucceeds(updateDoc(doc(db, 'publicProfiles', 'AAAAA'), {isOnline: true, lastSeen: serverTimestamp()}));
});
test('library creates and edits are private, validated, and keep a single record', async () => {
  const db = client('alice'), ref = doc(db, 'libraries', 'AAAAA', 'books', 'one');
  const book = {bookId: 'volume', title: 'Book', author: 'Author', imageurl: '', pages: 100,
    rating: 4, review: 'Good', updatedAt: serverTimestamp()};
  await assertSucceeds(setDoc(ref, book));
  await assertSucceeds(setDoc(ref, {...book, rating: 5}));
  assert.equal((await getDocs(query(collection(db, 'libraries', 'AAAAA', 'books'), limit(50)))).size, 1);
  await assertFails(setDoc(doc(client('bob'), 'libraries', 'AAAAA', 'books', 'one'), book));
  await assertFails(setDoc(ref, {...book, rating: 6}));
  await assertFails(setDoc(ref, {...book, review: 'x'.repeat(2001)}));
});
test('new two-party conversations require actual participants and canonical IDs', async () => {
  await provision(client('charlie'), 'charlie', 'CCCCC');
  const db = client('alice');
  await assertSucceeds(getDoc(doc(db, 'relationships', 'AAAAA_CCCCC')));
  await assertSucceeds(setDoc(doc(db, 'relationships', 'AAAAA_CCCCC'), {members: ['AAAAA', 'CCCCC'], blockedBy: []}));
  await assertFails(setDoc(doc(db, 'relationships', 'BBBBB_CCCCC'), {members: ['BBBBB', 'CCCCC'], blockedBy: []}));
  await assertFails(setDoc(doc(db, 'relationships', 'CCCCC_AAAAA'), {members: ['AAAAA', 'CCCCC'], blockedBy: []}));
  await assertFails(getDoc(doc(db, 'relationships', 'BBBBB_CCCCC')));
});
test('blocking revokes chat and the other participant cannot clear or forge the block', async () => {
  const alice = client('alice'), bob = client('bob');
  await assertSucceeds(block(bob, 'BBBBB', 'AAAAA', ['BBBBB']));
  await assertFails(setDoc(doc(alice, 'chat', 'AAAAA_BBBBB', 'messages', 'one'), message()));
  await assertFails(getDocs(query(collection(alice, 'chat', 'AAAAA_BBBBB', 'messages'), limit(50))));
  await assertFails(updateDoc(doc(alice, 'relationships', 'AAAAA_BBBBB'), {blockedBy: []}));
  await assertFails(updateDoc(doc(alice, 'relationships', 'AAAAA_BBBBB'), {members: ['AAAAA', 'CCCCC']}));
  await assertSucceeds(block(bob, 'BBBBB', 'AAAAA', []));
  await assertSucceeds(setDoc(doc(alice, 'chat', 'AAAAA_BBBBB', 'messages', 'one'), message()));
  await assertFails(updateDoc(doc(alice, 'relationships', 'AAAAA_BBBBB'), {blockedBy: ['BBBBB']}));
});
test('chat rejects spoofing, oversized messages and edits', async () => {
  const db = client('alice'), ref = doc(db, 'chat', 'AAAAA_BBBBB', 'messages', 'one');
  await assertSucceeds(setDoc(ref, message()));
  await assertFails(updateDoc(ref, {text: 'edited'}));
  await assertFails(setDoc(doc(db, 'chat', 'AAAAA_BBBBB', 'messages', 'two'), {...message(), senderId: 'BBBBB'}));
  await assertFails(setDoc(doc(db, 'chat', 'AAAAA_BBBBB', 'messages', 'three'), {...message(), text: 'x'.repeat(2001)}));
});
test('quiz submission is atomic and concurrent retries do not award XP twice', async () => {
  const db = client('alice'), ref = doc(db, 'quizAttempts', 'attempt');
  await assertSucceeds(setDoc(ref, quiz('alice')));
  await assertFails(getDoc(doc(client('bob'), 'quizAttempts', 'attempt')));
  const submit = () => runTransaction(db, async tx => {
    const attempt = await tx.get(ref), meRef = doc(db, 'users', 'AAAAA');
    const me = (await tx.get(meRef)).data();
    if (attempt.data().completed) return attempt.data().result;
    const patch = rewardState(me, 10, 5);
    const result = {correctCount: 5, gainedXp: 10};
    tx.update(meRef, patch);
    tx.update(doc(db, 'publicProfiles', 'AAAAA'), publicProfile(patch));
    tx.update(ref, {completed: true, completedAt: serverTimestamp(), result});
    return result;
  });
  // Rules can reject the stale second commit before the SDK sees its conflict.
  // The Dart client reads the immutable committed result on this path too.
  const safelySubmit = async () => {
    try { return await submit(); } catch (error) {
      if (!['permission-denied', 'aborted'].includes(error.code)) throw error;
      const saved = (await getDoc(ref)).data();
      if (!saved?.completed) throw error;
      return saved.result;
    }
  };
  const results = await Promise.all([safelySubmit(), safelySubmit()]);
  assert.deepEqual(results[0], results[1]);
  assert.equal((await getDoc(doc(db, 'users', 'AAAAA'))).data().xp, 10);
  await assertFails(updateDoc(ref, {completed: false}));
  await assertFails(updateDoc(ref, {questions: []}));
});
test('reports are authored by the caller and are not exposed to their target', async () => {
  const db = client('alice');
  const report = {reporter: 'AAAAA', reported: 'BBBBB', reason: 'Abusive chat', timestamp: serverTimestamp()};
  await assertSucceeds(setDoc(doc(db, 'reports', 'one'), report));
  await assertFails(setDoc(doc(db, 'reports', 'two'), {...report, reporter: 'BBBBB'}));
  await assertFails(getDoc(doc(client('bob'), 'reports', 'one')));
  await setDoc(doc(db, 'quizAttempts', 'quiz'), quiz('alice'));
  const content = {reporter: 'AAAAA', reason: 'Wrong answer', attemptId: 'quiz', questionIndex: 0,
    question: quiz('alice').questions[0], bookId: 'volume', title: 'Book', timestamp: serverTimestamp()};
  await assertSucceeds(setDoc(doc(db, 'reported_content', 'quiz_0'), content));
  await assertFails(setDoc(doc(db, 'reported_content', 'fake'), {...content, question: {question: 'forged'}}));
});
test('weekly snapshots are owner-only and old windows cannot be reopened', async () => {
  const db = client('alice');
  const start = new Date(`${weekKey()}T00:00:00Z`), end = new Date(start.getTime() + 7 * 86400000);
  const row = {friendCode: 'AAAAA', score: 0, leagueIndex: 0, weekStart: Timestamp.fromDate(start), weekEnd: Timestamp.fromDate(end)};
  const ref = doc(db, 'weeklyScores', weekKey(), 'players', 'AAAAA');
  await assertSucceeds(setDoc(ref, row));
  await assertFails(setDoc(doc(client('bob'), 'weeklyScores', weekKey(), 'players', 'AAAAA'), row));
  await assertFails(setDoc(ref, {...row, weekEnd: Timestamp.fromMillis(end.getTime() + 86400000)}));
  await assertFails(setDoc(ref, {...row, score: 999}));
  const oldWeek = weekKey(new Date(start.getTime() - 86400000));
  await env.withSecurityRulesDisabled(async context => {
    // Earlier server-written snapshots did not have explicit time windows.
    await setDoc(doc(context.firestore(), 'weeklyScores', weekKey(), 'players', 'AAAAA'), {friendCode: 'AAAAA', score: 0, leagueIndex: 0});
    await setDoc(doc(context.firestore(), 'weeklyScores', oldWeek, 'players', 'AAAAA'), {friendCode: 'AAAAA', score: 0, leagueIndex: 0});
  });
  await assertSucceeds(setDoc(ref, row));
  await assertFails(setDoc(doc(db, 'weeklyScores', oldWeek, 'players', 'AAAAA'), row));
});
test('deletion blocks writes, cleans owned data and reserves the friend code', async () => {
  const db = client('alice'), bob = client('bob');
  const msg = doc(db, 'chat', 'AAAAA_BBBBB', 'messages', 'one');
  await setDoc(msg, message());
  await updateDoc(doc(db, 'accounts', 'alice'), {deleting: true});
  await assertFails(setDoc(doc(bob, 'chat', 'AAAAA_BBBBB', 'messages', 'two'), {...message(), senderId: 'BBBBB', receiverId: 'AAAAA'}));
  await assertFails(updateDoc(doc(db, 'users', 'AAAAA'), {friends: ['BBBBB']}));
  await assertFails(updateDoc(doc(db, 'accounts', 'alice'), {deleting: false}));
  await assertSucceeds(getDocs(query(collection(db, 'relationships'), where('members', 'array-contains', 'AAAAA'), limit(100))));
  await assertSucceeds(getDocs(query(collection(db, 'chat', 'AAAAA_BBBBB', 'messages'), limit(100))));
  await assertSucceeds(deleteDoc(msg));
  await assertSucceeds(deleteDoc(doc(db, 'relationships', 'AAAAA_BBBBB')));
  const batch = writeBatch(db);
  batch.delete(doc(db, 'users', 'AAAAA'));
  batch.set(doc(db, 'publicProfiles', 'AAAAA'), {friendCode: 'AAAAA', deleted: true});
  await assertSucceeds(batch.commit());
  assert.equal(await provision(client('charlie'), 'charlie', 'AAAAA'), null);
  await assertFails(deleteDoc(doc(db, 'publicProfiles', 'AAAAA')));
});
