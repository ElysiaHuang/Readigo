'use strict';
const {test} = require('node:test');
const assert = require('node:assert/strict');
const {randomUUID} = require('node:crypto');
const {execFile} = require('node:child_process');
const {promisify} = require('node:util');
const {initializeApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore, Timestamp} = require('firebase-admin/firestore');
const projectId = 'demo-bookfania';
if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error('API integration tests require local Firestore and Auth emulators.');
}
initializeApp({projectId});
const db = getFirestore(), auth = getAuth();
const endpoint = `http://127.0.0.1:5001/${projectId}/us-central1/api`;
async function call(token, path, body = {}) {
  const response = await fetch(`${endpoint}${path}`, {method: 'POST', headers: {'Content-Type': 'application/json', Authorization: `Bearer ${token}`}, body: JSON.stringify(body)});
  return {status: response.status, body: await response.json()};
}
async function reader() {
  const email = `${randomUUID()}@example.com`, password = 'emulator-only-password';
  const user = await auth.createUser({email, password});
  const response = await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=emulator`, {
    method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify({email, password, returnSecureToken: true}),
  });
  const {idToken: token} = await response.json();
  assert.ok(token);
  return {uid: user.uid, token};
}
async function provision() {
  const user = await reader(), result = await call(user.token, '/provision', {username: 'Reader'});
  assert.equal(result.status, 200, JSON.stringify(result.body));
  return {...user, code: result.body.friendCode};
}
async function attempt(user) {
  const ref = db.collection('quizAttempts').doc();
  const questions = Array.from({length: 5}, (_, i) => ({question: `Question ${i}`, choices: ['A','B','C','D'], answer: 1}));
  await ref.set({uid: user.uid, friendCode: user.code, bookId: 'volume', title: 'Book', count: 5, difficulty: 4, questions, completed: false, expiresAt: Timestamp.fromMillis(Date.now() + 3600000)});
  return ref.id;
}

test('concurrent provisioning creates exactly one UID-bound profile', async () => {
  const user = await reader();
  const results = await Promise.all([call(user.token, '/provision', {username: 'Reader'}), call(user.token, '/provision', {username: 'Reader'})]);
  results.forEach(result => assert.equal(result.status, 200, JSON.stringify(result.body)));
  assert.equal(results[0].body.friendCode, results[1].body.friendCode);
  const profiles = await db.collection('users').where('ownerUid', '==', user.uid).get();
  assert.equal(profiles.size, 1);
});
test('repeated quiz submission awards XP once and returns the original result', async () => {
  const user = await provision(), id = await attempt(user);
  const body = {attemptId: id, answers: [1,1,1,1,1]};
  const results = await Promise.all([call(user.token, '/quiz/submit', body), call(user.token, '/quiz/submit', body)]);
  results.forEach(result => assert.equal(result.status, 200, JSON.stringify(result.body)));
  assert.deepEqual(results[0].body, results[1].body);
  assert.equal((await db.doc(`users/${user.code}`).get()).get('xp'), 20);
  assert.equal((await db.doc(`users/${user.code}`).get()).get('daily_quest_progress.finish_quizzes'), 1);
});
test('different concurrent quiz attempts do not lose progress', async () => {
  const user = await provision(), ids = await Promise.all([attempt(user), attempt(user)]);
  const results = await Promise.all(ids.map(id => call(user.token, '/quiz/submit', {attemptId: id, answers: [1,1,1,1,1]})));
  results.forEach(result => assert.equal(result.status, 200, JSON.stringify(result.body)));
  const profile = await db.doc(`users/${user.code}`).get();
  assert.equal(profile.get('xp'), 40); assert.equal(profile.get('daily_quest_progress.finish_quizzes'), 2);
});
test('another user cannot submit an attempt and profile edits cannot mint XP', async () => {
  const owner = await provision(), stranger = await provision(), id = await attempt(owner);
  assert.equal((await call(stranger.token, '/quiz/submit', {attemptId: id, answers: [1,1,1,1,1]})).status, 404);
  assert.equal((await call(owner.token, '/profile', {xp: 999999})).status, 400);
  assert.equal((await db.doc(`users/${owner.code}`).get()).get('xp'), 0);
});
test('editing a saved book does not increase book count', async () => {
  const user = await provision();
  const book = {bookId: 'volume', title: 'Book', author: 'Author', pages: 10, rating: 3, review: 'First'};
  assert.equal((await call(user.token, '/library/save', book)).status, 200);
  assert.equal((await call(user.token, '/library/save', {...book, rating: 5, review: 'Updated'})).status, 200);
  assert.equal((await db.doc(`users/${user.code}`).get()).get('books_count'), 1);
  assert.equal((await db.collection(`libraries/${user.code}/books`).get()).size, 1);
});
test('deletion cleans multiple message batches and friend references before removing identity', async () => {
  const user = await provision(), friend = await provision();
  const quiz = await attempt(user);
  assert.equal((await call(user.token, '/quiz/report', {attemptId: quiz, questionIndex: 0, reason: 'Incorrect question'})).status, 200);
  assert.equal((await call(user.token, '/report-user', {friendCode: friend.code, reason: 'Inappropriate profile'})).status, 200);
  assert.equal((await db.doc(`reported_content/${quiz}_0`).get()).get('question.question'), 'Question 0');
  const rel = [user.code, friend.code].sort().join('_');
  await db.doc(`relationships/${rel}`).set({members: [user.code, friend.code], blockedBy: []});
  await db.doc(`users/${friend.code}`).update({friends: [user.code]});
  for (let offset = 0; offset < 401; offset += 100) {
    const batch = db.batch();
    for (let i = offset; i < Math.min(401, offset + 100); i++) batch.set(db.doc(`chat/${rel}/messages/m${i}`), {senderId: user.code, receiverId: friend.code, text: 'Hello', timestamp: Timestamp.now()});
    await batch.commit();
  }
  const result = await call(user.token, '/account/delete');
  assert.equal(result.status, 200, JSON.stringify(result.body));
  assert.equal((await db.doc(`users/${user.code}`).get()).exists, false);
  assert.equal((await db.collection(`chat/${rel}/messages`).get()).size, 0);
  assert.deepEqual((await db.doc(`users/${friend.code}`).get()).get('friends'), []);
  assert.equal((await db.doc(`reported_content/${quiz}_0`).get()).exists, false);
  assert.equal((await db.collection('reports').where('reporter', '==', user.code).get()).size, 0);
  await assert.rejects(auth.getUser(user.uid), {code: 'auth/user-not-found'});
});

test('weekly transitions are idempotent and cannot reset newly earned points', async () => {
  const d = require('../src/domain');
  const user = await provision(), currentWeek = d.weekKey();
  const previousWeek = d.weekKey(new Date(Date.now() - 7 * 86400000));
  const patch = {league_current_week: previousWeek, league_current_index: 2, league_weekly_score: 80};
  await db.doc(`users/${user.code}`).update(patch);
  await db.doc(`publicProfiles/${user.code}`).update(patch);
  await db.doc(`weeklyScores/${previousWeek}/players/${user.code}`).set({friendCode: user.code, score: 80, leagueIndex: 2});
  const results = await Promise.all([call(user.token, '/league/sync'), call(user.token, '/league/sync')]);
  results.forEach(result => assert.equal(result.status, 200, JSON.stringify(result.body)));
  let profile = await db.doc(`users/${user.code}`).get();
  assert.equal(profile.get('league_current_week'), currentWeek);
  assert.equal(profile.get('league_current_index'), 3);
  assert.equal(profile.get('league_history').length, 1);
  assert.equal((await db.doc(`weeklyScores/${previousWeek}`).get()).get('closed'), true);
  const id = await attempt(user);
  assert.equal((await call(user.token, '/quiz/submit', {attemptId: id, answers: [1,1,1,1,1]})).status, 200);
  assert.equal((await call(user.token, '/league/sync')).status, 200);
  profile = await db.doc(`users/${user.code}`).get();
  assert.equal(profile.get('league_weekly_score'), 20);
  assert.equal(profile.get('league_history').length, 1);
  const board = await call(user.token, '/league/board');
  assert.equal(board.status, 200, JSON.stringify(board.body));
  const own = board.body.users.find(entry => entry.friendCode === user.code);
  assert.equal(own.actualRank, 1);
  assert.equal(own.email, undefined);
  assert.equal(own.ownerUid, undefined);
});

test('legacy migration is a dry run by default and is safe to rerun', async () => {
  const user = await reader(), identity = await auth.getUser(user.uid);
  const friendCode = 'LEGACY';
  await db.doc(`users/${friendCode}`).set({email: identity.email, username: 'Legacy reader', level: 2, xp: 35,
    friends: [], blocked: [], books: [
      {title: 'Saved Book', author: 'Author', rating: 2, review: 'Original'},
      {title: 'Saved Book', author: 'Author', rating: 5, review: 'Updated'},
    ]});
  const run = args => promisify(execFile)(process.execPath, ['migrate.js', ...args], {env: {...process.env, GCLOUD_PROJECT: projectId}});
  await run([]);
  assert.equal((await db.doc(`accounts/${user.uid}`).get()).exists, false);
  await run(['--apply']);
  await run(['--apply']);
  const profile = await db.doc(`users/${friendCode}`).get();
  assert.equal(profile.get('ownerUid'), user.uid);
  assert.equal(profile.get('books_count'), 1);
  assert.equal(profile.get('xp'), 35);
  assert.equal(profile.get('books'), undefined);
  const books = await db.collection(`libraries/${friendCode}/books`).get();
  assert.equal(books.size, 1); assert.equal(books.docs[0].get('review'), 'Updated');
  assert.equal((await db.doc(`publicProfiles/${friendCode}`).get()).get('email'), undefined);
});

test('closed weeks reject new rewards without completing the attempt', async () => {
  const {weekKey} = require('../src/domain');
  const user = await provision(), id = await attempt(user);
  const week = db.doc(`weeklyScores/${weekKey()}`);
  await week.set({closed: true});
  try {
    const result = await call(user.token, '/quiz/submit', {attemptId: id, answers: [1,1,1,1,1]});
    assert.equal(result.status, 503, JSON.stringify(result.body));
    assert.equal((await db.doc(`users/${user.code}`).get()).get('xp'), 0);
    assert.equal((await db.doc(`quizAttempts/${id}`).get()).get('completed'), false);
  } finally {
    await week.set({closed: false});
  }
});
