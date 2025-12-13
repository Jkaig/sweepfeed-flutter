import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const onUserLevelUp = functions.firestore
    .document('users/{userId}')
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();

      const beforeLevel = before.dustBunniesSystem?.level ?? 0;
      const afterLevel = after.dustBunniesSystem?.level ?? 0;

      if (afterLevel > beforeLevel) {
        const userId = context.params.userId;
        const payload = {
          notification: {
            title: 'Level Up!',
            body: `Congratulations! You've reached level ${afterLevel}!`,
          },
        };

        const db = admin.firestore();
        const tokenDoc = await db.collection('fcmTokens').doc(userId).get();
        const token = tokenDoc.data()?.token as string | undefined;

        if (token) {
          try {
            await admin.messaging().sendToDevice(token, payload);
            console.log(`Level up notification sent to user ${userId}`);
          } catch (error) {
            console.error(`Error sending level up notification to user ${userId}:`, error);
          }
        }
      }
    });
