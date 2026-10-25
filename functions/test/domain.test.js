'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const d = require('../src/domain');
const question = {question: 'Who is the narrator?', choices: ['A', 'B', 'C', 'D'], answer: 2};

test('week boundaries use UTC, including a year boundary', () => {
  assert.equal(d.weekKey(new Date('2026-09-06T23:59:59Z')), '2026-08-31');
  assert.equal(d.weekKey(new Date('2026-09-07T00:00:00Z')), '2026-09-07');
  assert.equal(d.weekKey(new Date('2026-01-01T00:00:00Z')), '2025-12-29');
});
test('quiz schema rejects invalid choices, indexes, count and duplicate questions', () => {
  assert.deepEqual(d.validateQuestions([question], 1), [question]);
  for (const input of [[], [{...question, answer: -1}], [{...question, choices: ['A','A','C','D']}], [{...question, question: ''}]]) {
    assert.throws(() => d.validateQuestions(input, 1));
  }
  assert.throws(() => d.validateQuestions([question, question], 2));
});
test('scoring rejects missing and out-of-range selections', () => {
  assert.equal(d.scoreQuiz([question], [2]), 1);
  assert.equal(d.scoreQuiz([question], [1]), 0);
  for (const answers of [[], [-1], [4], ['2']]) assert.throws(() => d.scoreQuiz([question], answers));
});
test('level ups preserve all XP across multiple levels', () => {
  const result = d.rewardState({xp: 90, level: 1}, 240, 20, new Date('2026-09-07T12:00:00Z'));
  assert.equal(result.level, 3); assert.equal(result.xp, 30); assert.equal(result.next_level_xp, 300);
});
test('daily quests award monthly progress once and monthly badge once', () => {
  const now = new Date('2026-09-07T12:00:00Z');
  const user = {level: 1, xp: 0, monthly_quest_month: '2026-09', monthly_quest_progress: 18};
  const first = d.rewardState(user, 20, 10, now);
  assert.equal(first.monthly_quest_progress, 20); assert.equal(first.monthly_badges.length, 1);
  const second = d.rewardState(first, 20, 10, now);
  const third = d.rewardState(second, 20, 10, now);
  assert.equal(third.monthly_quest_progress, 20); assert.equal(third.monthly_badges.length, 1);
  assert.equal(third.streak_count, 1);
});
test('streaks reset after a missed day and quests reset at UTC month boundary', () => {
  const user = {level: 1, xp: 0, last_active_date: '2026-08-29', streak_count: 20,
    monthly_quest_month: '2026-08', monthly_quest_progress: 19,
    daily_quest_date: '2026-08-31', daily_quest_progress: {earn_xp: 20, correct_answers: 10, finish_quizzes: 2}};
  const result = d.rewardState(user, 4, 1, new Date('2026-09-01T00:00:00Z'));
  assert.equal(result.streak_count, 1); assert.equal(result.monthly_quest_progress, 0);
  assert.deepEqual(result.daily_quest_progress, {earn_xp: 4, finish_quizzes: 1, correct_answers: 1});
});
test('inactive players never promote and promotion/demotion do not overlap', () => {
  assert.equal(d.transitionLeague(2, 0, 1, 1), 2);
  assert.equal(d.transitionLeague(2, 20, 5, 6), 3);
  assert.equal(d.transitionLeague(2, 20, 6, 6), 1);
  assert.equal(d.transitionLeague(9, 20, 1, 20), 9);
});
test('library identity ignores review edits and normalizes legacy titles', () => {
  assert.equal(d.libraryId({bookId: 'one', title: 'Book', author: 'A', rating: 1}), d.libraryId({bookId: 'one', title: 'Book', author: 'A', rating: 5}));
  assert.equal(d.libraryId({title: ' Book ', author: 'AUTHOR'}), d.libraryId({title: 'book', author: 'author'}));
});
test('public projection never includes private fields', () => {
  assert.deepEqual(d.publicProfile({username: 'Reader', xp: 12, email: 'private', ownerUid: 'private', friends: ['private'], blocked: ['private'], activity_dates: ['private'], books: ['private']}), {username: 'Reader', xp: 12});
});
