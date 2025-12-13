const {onSchedule} = require("firebase-functions/v2/scheduler");
const {logger} = require("firebase-functions/v2");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();
const fcm = getMessaging();

/**
 * Monthly Leaderboard Rewards
 * Runs on the 1st of every month at 00:00
 */
exports.processMonthlyRewards = onSchedule(
    {
        schedule: "0 0 1 * *", // 1st of month at 00:00
        timeZone: "UTC",
    },
    async (event) => {
  logger.info("Starting monthly leaderboard rewards processing...");

  try {
    const now = new Date();
    // Calculate last month string (e.g., "October 2023")
    const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const monthName = lastMonth.toLocaleString('default', { month: 'long', year: 'numeric' });

    // 1. Get Top 10 Users (Updated requirement)
    const leaderboardSnapshot = await db.collection("users")
      .orderBy("dustBunniesSystem.monthlyEarned", "desc") // Use verified monthly field
      .limit(10)
      .get();

    if (leaderboardSnapshot.empty) {
      logger.info("No users found for leaderboard.");
      return;
    }

    const topUsers = [];
    const batch = db.batch();
    const notifications = [];

    // 2. Process Winners
    leaderboardSnapshot.docs.forEach((doc, index) => {
      const user = doc.data();
      const userId = doc.id;
      const rank = index + 1;
      const points = user.dustBunniesSystem?.monthlyEarned || 0;

      topUsers.push({
        userId,
        name: user.name || "Anonymous",
        points: points,
        rank
      });

      // Grant Free Pro Subscription (1 Month)
      const oneMonthLater = new Date();
      oneMonthLater.setMonth(oneMonthLater.getMonth() + 1);

      const userRef = db.collection("users").doc(userId);
      batch.update(userRef, {
        "subscription.status": "active",
        "subscription.plan": "pro", // or 'premium'
        "subscription.source": "leaderboard_reward",
        "subscription.endDate": oneMonthLater,
        "subscription.updatedAt": new Date(),
      });

      // Prepare Notification
      if (user.fcmToken) {
        notifications.push(fcm.send({
          token: user.fcmToken,
          notification: {
            title: "🏆 You Won a Free Subscription!",
            body: `Congratulations! You ranked #${rank} in the ${monthName} leaderboard. Enjoy 1 month of Pro access!`,
          },
          data: {
            type: "reward_claimed",
            rank: rank.toString(),
          }
        }));
      }
      
      // Log Notification to user's collection (for in-app history)
      const notifRef = userRef.collection('notifications').doc();
      batch.set(notifRef, {
        title: "🏆 You Won a Free Subscription!",
        body: `Congratulations! You ranked #${rank} in the ${monthName} leaderboard. Enjoy 1 month of Pro access!`,
        read: false,
        createdAt: new Date(),
        type: 'reward'
      });
    });

    // 3. Archive Leaderboard
    const archiveRef = db.collection("leaderboard_history").doc(`${lastMonth.getFullYear()}_${lastMonth.getMonth() + 1}`);
    batch.set(archiveRef, {
      month: monthName,
      createdAt: new Date(),
      winners: topUsers
    });

    // 4. Commit Updates
    await batch.commit();
    await Promise.all(notifications);

    logger.info(`Successfully processed rewards for ${topUsers.length} users.`);

    // 5. Reset Monthly Points (Optional - depending on game logic)
    // If you want to reset points, you would do a separate batched write here
    // iterating through all users. For large user bases, use a separate triggered function.

  } catch (error) {
    logger.error("Error processing monthly rewards:", error);
  }
});
