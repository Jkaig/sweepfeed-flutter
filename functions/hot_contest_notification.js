const {onMessagePublished} = require("firebase-functions/v2/pubsub");
const {logger} = require("firebase-functions/v2");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

const db = getFirestore();
const fcm = getMessaging();

exports.sendHotContestNotification = onMessagePublished("hot-contests", async (event) => {
  const message = event.data.message;
  const contestIds = message.json.contestIds;

  if (!contestIds || contestIds.length === 0) {
    logger.info("No hot contests to notify.");
    return;
  }

  try {
    const promises = [];
    for (const contestId of contestIds) {
      const contestDoc = await db.collection("contests").doc(contestId).get();
      if (!contestDoc.exists) {
        continue;
      }
      const contest = contestDoc.data();
      const contestTitle = contest.title;

      const payload = {
        notification: {
          title: "🔥 Hot Sweepstake Alert!",
          body: `A sweepstake is getting a lot of attention: ${contestTitle}`,
        },
        data: {
          contestId: contestId,
          type: "hot_contest",
        },
        topic: "premium-hot-contests",
      };
      promises.push(fcm.send(payload));
    }

    await Promise.all(promises);
    logger.info(`Sent notifications for ${contestIds.length} hot contests.`);
  } catch (error) {
    logger.error("Error sending hot contest notifications.", error);
  }
});
