const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

initializeApp();
const db = getFirestore();

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
