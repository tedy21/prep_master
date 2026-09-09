const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { GoogleGenerativeAI } = require('@google/generative-ai');

initializeApp();
const db = getFirestore();

/**
 * Gemini API key — set once:
 *   firebase functions:secrets:set GEMINI_API_KEY
 * Then deploy:
 *   firebase deploy --only functions
 */
const geminiApiKey = defineSecret('GEMINI_API_KEY');

const MODEL = 'gemini-2.0-flash';
const STALE_MS = 6 * 60 * 60 * 1000;

/**
 * When a user's progress summary changes, mirror XP into the global leaderboard.
 */
exports.syncLeaderboardOnProgress = onDocumentWritten(
  'users/{userId}/progress/summary',
  async (event) => {
    const after = event.data?.after;
    if (!after?.exists) return;

    const userId = event.params.userId;
    const data = after.data() || {};
    const totalXP = data.totalXP || 0;

    const profileSnap = await db.doc(`users/${userId}`).get();
    const name = profileSnap.data()?.name || 'Learner';

    await db.doc(`leaderboard/global/entries/${userId}`).set(
      {
        name,
        totalXP,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  },
);

/**
 * Callable: generateProgressInsights
 * Auth required. Stores result at users/{uid}/progress/aiInsights.
 * Skips Gemini if a fresh insight exists unless data.force === true.
 */
exports.generateProgressInsights = onCall(
  { secrets: [geminiApiKey], timeoutSeconds: 60 },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError('unauthenticated', 'Sign in required');
    }

    const uid = request.auth.uid;
    const force = Boolean(request.data?.force);
    const stats = request.data?.stats || {};
    const insightRef = db.doc(`users/${uid}/progress/aiInsights`);

    if (!force) {
      const existing = await insightRef.get();
      if (existing.exists) {
        const d = existing.data() || {};
        const generatedAt = d.generatedAt?.toDate?.() || null;
        const isFallback = Boolean(d.isFallback);
        if (
          generatedAt &&
          !isFallback &&
          Date.now() - generatedAt.getTime() < STALE_MS
        ) {
          return {
            headline: d.headline,
            summary: d.summary,
            strengths: d.strengths || [],
            weakAreas: d.weakAreas || [],
            nextActions: d.nextActions || [],
            encouragement: d.encouragement || '',
            model: d.model || MODEL,
            isFallback: false,
            generatedAt: generatedAt.toISOString(),
            cached: true,
          };
        }
      }
    }

    const apiKey = geminiApiKey.value();
    if (!apiKey) {
      throw new HttpsError('failed-precondition', 'GEMINI_API_KEY is not set');
    }

    const prompt = buildPrompt(stats);
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
      model: MODEL,
      generationConfig: {
        temperature: 0.6,
        responseMimeType: 'application/json',
      },
    });

    let parsed;
    try {
      const result = await model.generateContent(prompt);
      const text = result.response.text();
      parsed = JSON.parse(text);
    } catch (err) {
      console.error('Gemini generateProgressInsights failed', err);
      throw new HttpsError('internal', 'AI coach generation failed');
    }

    const insight = {
      headline: String(parsed.headline || 'Your study coach').slice(0, 120),
      summary: String(parsed.summary || '').slice(0, 600),
      strengths: asStringArray(parsed.strengths).slice(0, 4),
      weakAreas: asStringArray(parsed.weakAreas).slice(0, 4),
      nextActions: asStringArray(parsed.nextActions).slice(0, 4),
      encouragement: String(parsed.encouragement || '').slice(0, 240),
      model: MODEL,
      isFallback: false,
      generatedAt: FieldValue.serverTimestamp(),
    };

    await insightRef.set(insight, { merge: true });

    return {
      ...insight,
      generatedAt: new Date().toISOString(),
      cached: false,
    };
  },
);

function asStringArray(value) {
  if (!Array.isArray(value)) return [];
  return value.map((v) => String(v)).filter(Boolean);
}

function buildPrompt(stats) {
  return `You are PrepMaster, an encouraging exam-prep coach for IELTS and SAT learners.
Given this learner's stats JSON, return ONLY valid JSON with keys:
headline (short), summary (2-3 sentences), strengths (string array),
weakAreas (string array), nextActions (string array of concrete practice steps),
encouragement (one short sentence).

Be specific to the skill names provided. No markdown. No extra keys.

Learner stats:
${JSON.stringify(stats)}`;
}
