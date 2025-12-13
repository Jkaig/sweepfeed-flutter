const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {logger} = require("firebase-functions/v2");

const db = getFirestore();
const fcm = getMessaging();

/**
 * Notify user when they are announced as a winner
 */
exports.onWinnerAnnounced = onDocumentCreated("winners/{winnerId}", async (event) => {
  const winner = event.data.data();
  const userId = winner.userId;
  const contestTitle = winner.contestTitle;
  const prizeName = winner.prizeDescription || winner.prizeName;

  if (!userId) return;

  try {
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) return;

    const token = userDoc.data().fcmToken;
    if (!token) return;

    await fcm.send({
      token: token,
      notification: {
        title: "🎉 You Won!",
        body: `Congratulations! You won ${prizeName} in ${contestTitle}! Tap to claim your prize.`,
      },
      data: {
        type: "winner_announcement",
        winnerId: event.params.winnerId,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    });

    logger.info(`Winner notification sent to user ${userId}`);
  } catch (error) {
    logger.error("Error sending winner notification:", error);
  }
});

/**
 * Notify user when their win verification status changes
 */
exports.onWinnerStatusUpdated = onDocumentUpdated("winners/{winnerId}", async (event) => {
  const oldData = event.data.before.data();
  const newData = event.data.after.data();
  const userId = newData.userId;

  // Only notify if status changed
  if (oldData.status === newData.status) return;

  try {
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists || !userDoc.data().fcmToken) return;

    const token = userDoc.data().fcmToken;
    let title = "";
    let body = "";

    switch (newData.status) {
      case "verified":
        title = "✅ Verification Approved";
        body = "Your win has been verified! We are preparing your prize.";
        break;
      case "disputed": // or rejected
        title = "⚠️ Verification Issue";
        body = "There is an issue with your verification. Please check the app.";
        break;
      case "claimed":
        title = "🎁 Prize Claimed";
        body = "Your prize has been successfully claimed and is on its way!";
        break;
      default:
        return;
    }

    await fcm.send({
      token: token,
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: "winner_status_update",
        winnerId: event.params.winnerId,
        status: newData.status,
      },
    });

    logger.info(`Status update notification (${newData.status}) sent to user ${userId}`);
  } catch (error) {
    logger.error("Error sending status update notification:", error);
  }
});
