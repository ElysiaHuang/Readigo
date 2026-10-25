'use strict';
const {createHash} = require('node:crypto');
const GOALS = {earn_xp: 20, finish_quizzes: 2, correct_answers: 10};
const LEAGUES = ['Scribbler (Beginner)', 'Storyteller', 'Reader', 'Novel Enthusiast', 'Page Turner', 'Bookworm', 'Plot Navigator', 'Literary Champion', 'Epic Reader', 'Legendary Librarian'];
const dateKey = date => date.toISOString().slice(0, 10);
function weekKey(date = new Date()) {
  const day = new Date(`${dateKey(date)}T00:00:00Z`);
  day.setUTCDate(day.getUTCDate() - (day.getUTCDay() + 6) % 7);
  return dateKey(day);
}
function text(value, name, max, min = 1) {
  if (typeof value !== 'string' || value.trim().length < min || value.trim().length > max) {
    throw Object.assign(new Error(`Invalid ${name}.`), {status: 400});
  }
  return value.trim();
}
function integer(value, name, min, max) {
  if (!Number.isInteger(value) || value < min || value > max) throw Object.assign(new Error(`Invalid ${name}.`), {status: 400});
  return value;
}
const natural = value => Number.isSafeInteger(value) && value >= 0 ? value : 0;
function validateQuestions(value, count) {
  if (!Array.isArray(value) || value.length !== count) throw new Error('The quiz did not contain the requested number of questions.');
  const seen = new Set();
  return value.map(q => {
    const question = text(q?.question, 'question', 1000);
    if (seen.has(question.toLowerCase())) throw new Error('Duplicate question.');
    seen.add(question.toLowerCase());
    if (!Array.isArray(q.choices) || q.choices.length !== 4) throw new Error('Each question needs four choices.');
    const choices = q.choices.map(c => text(c, 'choice', 500));
    if (new Set(choices.map(c => c.toLowerCase())).size !== 4) throw new Error('Duplicate choices.');
    return {question, choices, answer: integer(q.answer, 'answer', 0, 3)};
  });
}
function quizSettings(body) {
  return {
    bookId: text(body.bookId, 'book ID', 100),
    difficulty: integer(body.difficulty, 'difficulty', 1, 12),
    count: integer(body.count, 'question count', 5, 25),
    chapterScope: text(body.chapterScope ?? '', 'chapter', 160, 0),
  };
}
function scoreQuiz(questions, answers) {
  if (!Array.isArray(answers) || answers.length !== questions.length) throw Object.assign(new Error('Answer every question before submitting.'), {status: 400});
  answers.forEach(a => integer(a, 'selected answer', 0, 3));
  return answers.filter((answer, i) => answer === questions[i].answer).length;
}
function rewardState(user, gainedXp, correctAnswers, now = new Date()) {
  const today = dateKey(now), month = today.slice(0, 7);
  const yesterday = dateKey(new Date(now.getTime() - 86400000));
  const startXp = natural(user.xp), startLevel = Math.max(1, natural(user.level));
  let xp = startXp + gainedXp, level = startLevel;
  while (xp >= level * 100) { xp -= level * 100; level++; }
  const prior = user.daily_quest_date === today ? user.daily_quest_progress ?? {} : {};
  const progress = {}, increments = {earn_xp: gainedXp, finish_quizzes: 1, correct_answers: correctAnswers};
  let monthly = user.monthly_quest_month === month ? Math.min(20, natural(user.monthly_quest_progress)) : 0;
  for (const [key, goal] of Object.entries(GOALS)) {
    const before = Math.min(goal, natural(prior[key]));
    progress[key] = Math.min(goal, before + increments[key]);
    if (before < goal && progress[key] === goal) monthly = Math.min(20, monthly + 1);
  }
  const badges = Array.isArray(user.monthly_badges) ? [...user.monthly_badges] : [];
  if (monthly === 20 && !badges.some(b => b.monthKey === month)) {
    const label = now.toLocaleString('en-US', {month: 'long', timeZone: 'UTC'});
    badges.unshift({monthKey: month, title: `${label} Quest`, monthLabel: label, year: now.getUTCFullYear(), earnedAt: today});
  }
  return {
    xp, level, next_level_xp: level * 100,
    streak_count: user.last_active_date === today ? natural(user.streak_count) : user.last_active_date === yesterday ? natural(user.streak_count) + 1 : 1,
    last_active_date: today,
    activity_dates: [...new Set([...(user.activity_dates ?? []), today])].sort().slice(-28),
    daily_quest_date: today, daily_quest_progress: progress,
    monthly_quest_month: month, monthly_quest_progress: monthly, monthly_badges: badges,
  };
}
function transitionLeague(index, score, rank, size) {
  if (score <= 0) return index;
  if (rank <= 5) return Math.min(LEAGUES.length - 1, index + 1);
  if (rank > size - 3) return Math.max(0, index - 1);
  return index;
}
function libraryId(book) {
  return createHash('sha256').update(book.bookId || `${book.title.trim().toLowerCase()}\n${book.author.trim().toLowerCase()}`).digest('hex');
}
function publicProfile(user) {
  const keys = ['username', 'username_lower', 'bio', 'profilePic', 'friendCode', 'level', 'xp', 'next_level_xp', 'books_count', 'league_current_index', 'league_current_week', 'league_weekly_score', 'league_history'];
  return Object.fromEntries(keys.filter(k => user[k] !== undefined).map(k => [k, user[k]]));
}
module.exports = {GOALS, LEAGUES, dateKey, weekKey, text, integer, natural, validateQuestions, quizSettings, scoreQuiz, rewardState, transitionLeague, libraryId, publicProfile};
