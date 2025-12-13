const {onSchedule} = require("firebase-functions/v2/scheduler");
const {logger} = require("firebase-functions/v2");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, Timestamp} = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

// Process monthly leaderboard - runs on the 1st of each month
exports.processMonthlyLeaderboard = onSchedule(
  {
    schedule: "0 0 1 * *",
    timeZone: "UTC",
  },
  async (event) => {

    try {
      const now = new Date();
      const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
      const lastMonthEnd = new Date(now.getFullYear(), now.getMonth(), 0);

      const monthKey = `${lastMonth.getFullYear()}-${String(lastMonth.getMonth() + 1).padStart(2, '0')}`;

      // Get top 100 users by monthly entries (updated to monthlyEarned)
      const leaderboardSnapshot = await db.collection("users")
        .orderBy("dustBunniesSystem.monthlyEarned", "desc")
        .limit(100)
        .get();

      const batch = db.batch();
      const leaderboardData = [];

      leaderboardSnapshot.docs.forEach((doc, index) => {
        const userData = doc.data();
        const monthlyEarned = userData.dustBunniesSystem?.monthlyEarned || 0;

        leaderboardData.push({
          rank: index + 1,
          userId: doc.id,
          displayName: userData.displayName || "Anonymous",
          monthlyEarned: monthlyEarned,
          photoUrl: userData.photoUrl || null,
        });
      });

      // Store historical leaderboard (plural collection name per rules)
      const leaderboardRef = db.collection("leaderboards").doc(monthKey);
      batch.set(leaderboardRef, {
        month: monthKey,
        processedAt: Timestamp.now(),
        topUsers: leaderboardData,
      });

      // Reset monthly entries for all users
      // NOTE: For large scale apps, consider using a separate triggered function or batched jobs
      const allUsersSnapshot = await db.collection("users").get();
      allUsersSnapshot.docs.forEach((doc) => {
        batch.update(doc.ref, {
          "dustBunniesSystem.monthlyEarned": 0,
          monthlyEntries: 0, // Reset legacy field too
          lastMonthlyReset: Timestamp.now(),
        });
      });

      await batch.commit();
      logger.info(`Monthly leaderboard processed for ${monthKey}`);
      return null;
    } catch (error) {
      logger.error("Error processing monthly leaderboard:", error);
      throw error;
    }
  }
);
