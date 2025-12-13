import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const onNewChallenge = functions.firestore
    .document('challenges/{challengeId}')
    .onCreate(async (snap, context) => {
      const challenge = snap.data();
      const challengedId = challenge.challengedId;

      const payload = {
        notification: {
          title: 'New Challenge!',
          body: `You have been challenged by ${challenge.challengerName}!`,
        },
      };

      const db = admin.firestore();
      const tokenDoc = await db.collection('fcmTokens').doc(challengedId).get();
      const token = tokenDoc.data()?.token as string | undefined;

      if (token) {
        try {
          await admin.messaging().sendToDevice(token, payload);
          console.log(`New challenge notification sent to user ${challengedId}`);
        } catch (error) {
          console.error(`Error sending new challenge notification to user ${challengedId}:`, error);
        }
      }
    });
