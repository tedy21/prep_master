#!/usr/bin/env node
/**
 * Seeds Firestore with PrepMaster quiz content from assets/data/quiz_bank.json.
 *
 * Content is stored in `quiz_questions` (flat, CMS-friendly) so the mobile app
 * can fetch updates without an App Store release.
 *
 * Prerequisites:
 *   cd functions && npm install
 *   export GOOGLE_APPLICATION_CREDENTIALS=./serviceAccount.json
 *   npm run seed
 */

const fs = require('fs');
const path = require('path');

// firebase-admin is installed in functions/node_modules
module.paths.unshift(path.join(__dirname, '../functions/node_modules'));

const SECTION_KEYS = {
  sat: ['math', 'english'],
  ielts: ['listening', 'reading', 'writing', 'speaking'],
};

const MOCK_TESTS = [
  {
    id: 'sat-full-1',
    title: 'SAT Full-Length Mock',
    examType: 'sat',
    durationMinutes: 134,
    sectionCount: 2,
    isTimed: true,
    questionIds: [
      'sat-math-001', 'sat-math-002', 'sat-math-003',
      'sat-rw-001', 'sat-rw-002', 'sat-rw-003',
      'sat-math-004', 'sat-math-005',
    ],
  },
  {
    id: 'sat-math-1',
    title: 'SAT Math Practice Test',
    examType: 'sat',
    durationMinutes: 70,
    sectionCount: 1,
    isTimed: true,
    section: 'math',
    questionIds: [
      'sat-math-001', 'sat-math-002', 'sat-math-003',
      'sat-math-004', 'sat-math-005',
    ],
  },
  {
    id: 'sat-english-1',
    title: 'SAT Reading & Writing Practice Test',
    examType: 'sat',
    durationMinutes: 64,
    sectionCount: 1,
    isTimed: true,
    section: 'english',
    questionIds: [
      'sat-rw-001', 'sat-rw-002', 'sat-rw-003',
      'sat-rw-004', 'sat-rw-005',
    ],
  },
  {
    id: 'ielts-full-1',
    title: 'IELTS Academic Full Mock',
    examType: 'ielts',
    durationMinutes: 165,
    sectionCount: 4,
    isTimed: true,
    questionIds: [
      'ielts-listen-001', 'ielts-listen-002',
      'ielts-read-001', 'ielts-read-002', 'ielts-read-003',
      'ielts-write-001', 'ielts-write-002',
      'ielts-speak-001', 'ielts-speak-002',
    ],
  },
  {
    id: 'ielts-listening-1',
    title: 'IELTS Listening Practice Test',
    examType: 'ielts',
    durationMinutes: 40,
    sectionCount: 1,
    isTimed: true,
    section: 'listening',
    questionIds: ['ielts-listen-001', 'ielts-listen-002', 'ielts-listen-003', 'ielts-listen-004', 'ielts-listen-005'],
  },
  {
    id: 'ielts-reading-1',
    title: 'IELTS Reading Practice Test',
    examType: 'ielts',
    durationMinutes: 60,
    sectionCount: 1,
    isTimed: true,
    section: 'reading',
    questionIds: [
      'ielts-read-001', 'ielts-read-002', 'ielts-read-003',
      'ielts-read-004', 'ielts-gram-001',
    ],
  },
  {
    id: 'ielts-writing-1',
    title: 'IELTS Writing Practice Test',
    examType: 'ielts',
    durationMinutes: 60,
    sectionCount: 1,
    isTimed: true,
    section: 'writing',
    questionIds: [
      'ielts-write-001', 'ielts-write-002', 'ielts-write-003', 'ielts-write-005',
      'ielts-write-007', 'ielts-write-014', 'ielts-write-016', 'ielts-write-018',
    ],
  },
  {
    id: 'ielts-speaking-1',
    title: 'IELTS Speaking Practice Test',
    examType: 'ielts',
    durationMinutes: 15,
    sectionCount: 1,
    isTimed: true,
    section: 'speaking',
    questionIds: [
      'ielts-speak-001', 'ielts-speak-002',
      'ielts-speak-003', 'ielts-speak-004',
    ],
  },
];

function flattenSectionData(sectionData) {
  if (!Array.isArray(sectionData)) return [];

  const result = [];
  for (const item of sectionData) {
    if (item.questions) {
      const setId = item.id || '';
      const title = item.title || null;
      const contextBody = item.passage || item.transcript || null;
      const contextType = item.passage
        ? 'passage'
        : item.transcript
          ? 'transcript'
          : null;

      for (const q of item.questions) {
        result.push({
          ...q,
          ...(title && { contextTitle: title }),
          ...(contextBody && { contextBody }),
          ...(contextType && { contextType }),
          ...(setId && { contextSetId: setId }),
        });
      }
    } else {
      result.push(item);
    }
  }
  return result;
}

function collectQuestions(bank) {
  const questions = [];

  for (const examType of ['sat', 'ielts']) {
    const examData = bank[examType];
    if (!examData || typeof examData !== 'object') continue;

    for (const section of SECTION_KEYS[examType]) {
      const raw = flattenSectionData(examData[section]);
      for (const q of raw) {
        const { id, ...fields } = q;
        questions.push({
          id,
          examType,
          section,
          ...fields,
          updatedAt: new Date().toISOString(),
        });
      }
    }
  }

  return questions;
}

async function main() {
  const admin = require('firebase-admin');

  const credsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (!credsPath || !fs.existsSync(credsPath)) {
    console.error(`
Firebase credentials required to seed Firestore.

Option A (recommended):
  1. Firebase Console → Project Settings → Service accounts
  2. "Generate new private key" → save as functions/serviceAccount.json
  3. cd functions
  4. export GOOGLE_APPLICATION_CREDENTIALS=./serviceAccount.json
  5. npm run seed

Option B:
  firebase login
  gcloud auth application-default login
  npm run seed
`);
    process.exit(1);
  }

  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(require(credsPath)),
      projectId: 'prepmaster-tedy21',
    });
  }
  const db = admin.firestore();

  const bankPath = path.join(__dirname, '../assets/data/quiz_bank.json');
  const seedPath = path.join(__dirname, '../assets/data/firestore_seed.json');
  const bank = JSON.parse(fs.readFileSync(bankPath, 'utf8'));
  const seed = JSON.parse(fs.readFileSync(seedPath, 'utf8'));

  const questions = collectQuestions(bank);
  console.log(`Seeding ${questions.length} questions to quiz_questions...`);

  let batch = db.batch();
  let ops = 0;

  async function commitIfNeeded(force = false) {
    if (ops === 0) return;
    if (force || ops >= 400) {
      await batch.commit();
      batch = db.batch();
      ops = 0;
    }
  }

  for (const q of questions) {
    const { id, ...data } = q;
    batch.set(db.collection('quiz_questions').doc(id), data, { merge: true });
    ops += 1;
    await commitIfNeeded();
  }

  for (const test of MOCK_TESTS) {
    batch.set(db.collection('mock_tests').doc(test.id), test, { merge: true });
    ops += 1;
    await commitIfNeeded();
  }

  for (const test of seed.mock_tests || []) {
    if (!MOCK_TESTS.find((t) => t.id === test.id)) {
      batch.set(db.collection('mock_tests').doc(test.id), test, { merge: true });
      ops += 1;
      await commitIfNeeded();
    }
  }

  for (const w of seed.vocabulary?.sat || []) {
    const { id, ...data } = w;
    batch.set(
      db.collection('vocabulary').doc('sat').collection('words').doc(id),
      data,
      { merge: true },
    );
    ops += 1;
    await commitIfNeeded();
  }

  for (const w of seed.vocabulary?.ielts || []) {
    const { id, ...data } = w;
    batch.set(
      db.collection('vocabulary').doc('ielts').collection('words').doc(id),
      data,
      { merge: true },
    );
    ops += 1;
    await commitIfNeeded();
  }

  for (const g of seed.college_guides || []) {
    const { id, ...data } = g;
    batch.set(db.collection('college_guides').doc(id), data, { merge: true });
    ops += 1;
    await commitIfNeeded();
  }

  const counts = { sat: {}, ielts: {} };
  for (const q of questions) {
    counts[q.examType][q.section] =
      (counts[q.examType][q.section] || 0) + 1;
  }

  batch.set(
    db.doc('content_meta/catalog'),
    {
      version: Date.now(),
      questionCount: questions.length,
      mockTestCount: MOCK_TESTS.length,
      counts,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  ops += 1;

  await commitIfNeeded(true);
  console.log('Seed complete for project prepmaster-tedy21');
  console.log(`  quiz_questions: ${questions.length}`);
  console.log(`  mock_tests: ${MOCK_TESTS.length}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
