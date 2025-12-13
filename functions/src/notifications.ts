import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const sendNotification = functions.https.onCall(async (data, context) => {
  const userId = data.userId;
  const payload = data.payload;

  if (!userId || !payload) {
    throw new functions.https.HttpsError(
        'invalid-argument',
        'The function must be called with "userId" and "payload" arguments.',
    );
  }

  const db = admin.firestore();
  const tokenDoc = await db.collection('fcmTokens').doc(userId).get();
  const token = tokenDoc.data()?.token as string | undefined;

  if (!token) {
    console.log(`No token found for user ${userId}`);
    return {success: false, error: 'No token found'};
  }

  try {
    const message = {
      token: token,
      notification: {
        title: payload.notification.title,
        body: payload.notification.body,
      },
      data: payload.data,
      android: {
        notification: {
          imageUrl: payload.notification.imageUrl,
        },
      },
      apns: {
        payload: {
          aps: {
            'mutable-content': 1,
          },
        },
        fcm_options: {
          image: payload.notification.imageUrl,
        },
      },
    };

    await admin.messaging().send(message);
    console.log(`Notification sent to user ${userId}`);
    return {success: true};
  } catch (error) {
    console.error(`Error sending notification to user ${userId}:`, error);
    return {success: false, error: error};
  }
});
