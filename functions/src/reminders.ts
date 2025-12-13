import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const dailyEndingSoonReminder = functions.pubsub
    .schedule('every 24 hours')
    .onRun(async (context) => {
      const db = admin.firestore();
      const now = new Date();
      const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);

      const users = await db.collection('users').get();

      for (const user of users.docs) {
        const trackedContests = await db
            .collection('users')
            .doc(user.id)
            .collection('trackedContests')
            .where('endDate', '>=', today)
            .where('endDate', '<', tomorrow)
            .get();

        if (trackedContests.size > 0) {
          const payload = {
            notification: {
              title: 'Contests Ending Today!',
              body: `You have ${trackedContests.size} contests ending today.`,
            },
          };

          const tokenDoc = await db.collection('fcmTokens').doc(user.id).get();
          const token = tokenDoc.data()?.token as string | undefined;

          if (token) {
            try {
              await admin.messaging().sendToDevice(token, payload);
              console.log(`Ending soon reminder sent to user ${user.id}`);
            } catch (error) {
              console.error(`Error sending ending soon reminder to user ${user.id}:`, error);
            }
          }
        }
      }
    });

export const dailyEntryReminder = functions.pubsub
    .schedule('every 24 hours')
    .onRun(async (context) => {
        const db = admin.firestore();
        const users = await db.collection('users').get();

        for (const user of users.docs) {
            const trackedContests = await db
                .collection('users')
                .doc(user.id)
                .collection('trackedContests')
                .where('frequency', '==', 'daily')
                .get();

            if (trackedContests.size > 0) {
                const payload = {
                    notification: {
                        title: 'Daily Entries Available!',
                        body: `You have ${trackedContests.size} contests with daily entries available.`,
                    },
                };

                const tokenDoc = await db.collection('fcmTokens').doc(user.id).get();
                const token = tokenDoc.data()?.token as string | undefined;

                if (token) {
                    try {
                        await admin.messaging().sendToDevice(token, payload);
                        console.log(`Daily entry reminder sent to user ${user.id}`);
                    } catch (error) {
                        console.error(`Error sending daily entry reminder to user ${user.id}:`, error);
                    }
                }
            }
        }
    });

export const inactivityReminder = functions.pubsub
    .schedule('every 24 hours')
    .onRun(async (context) => {
        const db = admin.firestore();
        const now = new Date();
        const twoDaysAgo = new Date(now);
        twoDaysAgo.setDate(twoDaysAgo.getDate() - 2);

        const users = await db.collection('users').get();

        for (const user of users.docs) {
            const lastEntry = await db
                .collection('user_entries')
                .where('userId', '==', user.id)
                .orderBy('entryDate', 'desc')
                .limit(1)
                .get();

            if (lastEntry.empty || lastEntry.docs[0].data().entryDate.toDate() < twoDaysAgo) {
                const payload = {
                    notification: {
                        title: 'We miss you!',
                        body: 'You haven\'t entered any sweepstakes in the last 2 days.',
                    },
                };

                const tokenDoc = await db.collection('fcmTokens').doc(user.id).get();
                const token = tokenDoc.data()?.token as string | undefined;

                if (token) {
                    try {
                        await admin.messaging().sendToDevice(token, payload);
                        console.log(`Inactivity reminder sent to user ${user.id}`);
                    } catch (error) {
                        console.error(`Error sending inactivity reminder to user ${user.id}:`, error);
                    }
                }
            }
        }
    });