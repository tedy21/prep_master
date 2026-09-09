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

/**
 * Callable: evaluateSpeakingAttempt
 * Auth required. Scores an IELTS speaking answer with Gemini.
 * Stores attempt at users/{uid}/speakingAttempts/{autoId}.
 */
exports.evaluateSpeakingAttempt = onCall(
  { secrets: [geminiApiKey], timeoutSeconds: 90, memory: '512MiB' },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError('unauthenticated', 'Sign in required');
    }

    const uid = request.auth.uid;
    const data = request.data || {};
    const part = String(data.part || 'part1');
    const promptText = String(data.prompt || '').slice(0, 800);
    const cueBullets = asStringArray(data.cueBullets).slice(0, 8);
    const transcript = String(data.transcript || '').slice(0, 4000);
    const durationSec = Number(data.durationSec) || 0;
    const audioBase64 = typeof data.audioBase64 === 'string' ? data.audioBase64 : '';
    const mimeType = String(data.mimeType || 'audio/m4a').slice(0, 64);

    if (!promptText.trim()) {
      throw new HttpsError('invalid-argument', 'prompt is required');
    }
    if (!transcript.trim() && !audioBase64) {
      throw new HttpsError(
        'invalid-argument',
        'Provide a transcript and/or audioBase64',
      );
    }
    // Keep callable payload reasonable (~6MB text ceiling for base64 audio).
    if (audioBase64.length > 6_000_000) {
      throw new HttpsError('invalid-argument', 'Audio payload too large');
    }

    const apiKey = geminiApiKey.value();
    if (!apiKey) {
      throw new HttpsError('failed-precondition', 'GEMINI_API_KEY is not set');
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
      model: MODEL,
      generationConfig: {
        temperature: 0.45,
        responseMimeType: 'application/json',
      },
    });

    const parts = [
      { text: buildSpeakingEvalPrompt({ part, promptText, cueBullets, transcript, durationSec }) },
    ];
    if (audioBase64) {
      parts.push({
        inlineData: {
          mimeType: mimeType.startsWith('audio/') ? mimeType : 'audio/m4a',
          data: audioBase64,
        },
      });
    }

    let parsed;
    try {
      const result = await model.generateContent(parts);
      const text = result.response.text();
      parsed = JSON.parse(text);
    } catch (err) {
      console.error('Gemini evaluateSpeakingAttempt failed', err);
      throw new HttpsError('internal', 'Speaking evaluation failed');
    }

    const feedback = normalizeSpeakingFeedback(parsed, transcript);
    const attemptRef = db.collection(`users/${uid}/speakingAttempts`).doc();
    const stored = {
      ...feedback,
      part,
      prompt: promptText,
      cueBullets,
      durationSec,
      model: MODEL,
      createdAt: FieldValue.serverTimestamp(),
    };
    await attemptRef.set(stored);

    return {
      ...feedback,
      id: attemptRef.id,
      part,
      prompt: promptText,
      cueBullets,
      durationSec,
      model: MODEL,
      createdAt: new Date().toISOString(),
      isFallback: false,
    };
  },
);

function asStringArray(value) {
  if (!Array.isArray(value)) return [];
  return value.map((v) => String(v)).filter(Boolean);
}

function clampBand(value, fallback = 5.0) {
  const n = Number(value);
  if (!Number.isFinite(n)) return fallback;
  const clamped = Math.min(9, Math.max(0, n));
  return Math.round(clamped * 2) / 2;
}

function criterionFrom(raw, fallbackScore = 5.0) {
  const obj = raw && typeof raw === 'object' ? raw : {};
  return {
    score: clampBand(obj.score, fallbackScore),
    notes: asStringArray(obj.notes).slice(0, 4),
  };
}

function normalizeSpeakingFeedback(parsed, fallbackTranscript) {
  const grammar = criterionFrom(parsed.grammar);
  const vocabulary = criterionFrom(parsed.vocabulary);
  const fluency = criterionFrom(parsed.fluency);
  const pronunciation = criterionFrom(parsed.pronunciation);
  const avg =
    (grammar.score + vocabulary.score + fluency.score + pronunciation.score) / 4;
  return {
    transcript: String(parsed.transcript || fallbackTranscript || '').slice(0, 4000),
    grammar,
    vocabulary,
    fluency,
    pronunciation,
    bandEstimate: clampBand(parsed.bandEstimate, avg),
    feedback: String(parsed.feedback || '').slice(0, 800),
    improvedAnswer: String(parsed.improvedAnswer || '').slice(0, 1200),
    tips: asStringArray(parsed.tips).slice(0, 5),
  };
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

function buildSpeakingEvalPrompt({ part, promptText, cueBullets, transcript, durationSec }) {
  return `You are an IELTS Speaking examiner coach for PrepMaster.
Evaluate the candidate's answer for ${part}.
Return ONLY valid JSON with keys:
transcript (cleaned transcript string),
grammar ({ score: number 0-9 half bands allowed, notes: string[] }),
vocabulary ({ score, notes }),
fluency ({ score, notes }),
pronunciation ({ score, notes }),
bandEstimate (overall 0-9 half band),
feedback (2-4 sentences of personal coaching),
improvedAnswer (a stronger model answer the learner can study),
tips (string array of concrete next steps).

Rules:
- Be fair and specific; reference the prompt.
- If audio is attached, use it for pronunciation/fluency; otherwise rely on transcript.
- Prefer half-band scores (e.g. 5.5, 6.0, 6.5).
- No markdown. No extra keys.

Prompt: ${promptText}
Cue bullets: ${JSON.stringify(cueBullets)}
On-device transcript: ${transcript || '(none)'}
Duration seconds: ${durationSec}`;
}
