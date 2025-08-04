const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {logger} = require("firebase-functions/v2");
const {initializeApp} = require("firebase-admin/app");
const {Timestamp} = require("firebase-admin/firestore");

const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();
const fcm = getMessaging();

/**
 * Sends a notification to users when a new contest is created.
 */
exports.sendNewContestNotification = onDocumentCreated(
    "contests/{contestId}",
    async (event) => {
      const contestId = event.params.contestId;
      const contest = event.data.after.data();
      const contestTitle = contest.title;

      logger.info(`New contest created: ${contestTitle} (ID: ${contestId})`);

      try {
        // Get all users who have the 'new_sweepstakes' preference set to true.
        const usersSnapshot = await db
            .collection("users")
            .where("notification_preferences.new_sweepstakes", "==", true)
            .get();

        const promises = [];
        usersSnapshot.forEach((doc) => {
          const user = doc.data();
          const token = user.fcmToken;
          if (token) {
            const payload = {
              notification: {
                title: "New Sweepstake!",
                body: `A new sweepstake has been created: ${contestTitle}`,
              },
              data: {contestId: contestId},
              token: token,
            };
            promises.push(fcm.send(payload));
          }
        });

        await Promise.all(promises);
        logger.info("New contest notifications sent successfully.");
      } catch (error) {
        logger.error("Error sending new contest notifications.", error);
      }
    },
);

/**
 * Sends a notification to users about contests ending soon.
 * This function is scheduled to run periodically.
 */
exports.sendEndingSoonNotification = onSchedule("every day 00:00",
    async (event) => {
      const now = Timestamp.now();
      const oneDayLater = Timestamp.fromMillis(
          now.toMillis() + 24 * 60 * 60 * 1000,
      );

      logger.info("Checking for contests ending soon...");

      try {
        // Find contests ending in the next 24 hours.
        const contestsSnapshot = await db
            .collection("contests")
            .where("endDate", ">=", now)
            .where("endDate", "<=", oneDayLater)
            .get();

        const promises = [];
        contestsSnapshot.forEach(async (contestDoc) => {
          const contest = contestDoc.data();
          const contestId = contestDoc.id;
          const contestTitle = contest.title;

          // Get users who have the 'ending_soon' preference set to true.
          const usersSnapshot = await db
              .collection("users")
              .where("notification_preferences.ending_soon", "==", true)
              .get();

          usersSnapshot.forEach((userDoc) => {
            const user = userDoc.data();
            const token = user.fcmToken;
            if (token) {
              const payload = {
                notification: {
                  title: "Contest Ending Soon!",
                  body: `${contestTitle} is ending soon!`,
                },
                data: {
                  contestId: contestId,
                },
                token: token,
              };
              promises.push(fcm.send(payload));
            }
          });
        });
        await Promise.all(promises);
      } catch (error) {
        logger.error("Error sending ending soon notifications.", error);
      }
    },
);
