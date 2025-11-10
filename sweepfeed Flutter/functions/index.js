const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onCall} = require("firebase-functions/v2/https");
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

// ============================================================================
// REFERRAL CODE NOTIFICATION
// Triggered when someone uses a referral code
// ============================================================================
const {FieldValue} = require("firebase-admin/firestore");

exports.notifyReferralCodeUsed = onDocumentCreated(
    "referrals/{referralCodeId}/children/{childUserId}",
    async (event) => {
      const {referralCodeId, childUserId} = event.params;

      try {
        const codeDoc = await db.collection("referrals").doc(referralCodeId).get();

        if (!codeDoc.exists) {
          logger.error(`Referral code ${referralCodeId} not found`);
          return null;
        }

        const parentUserId = codeDoc.data().parentUserId;
        const ownerDoc = await db.collection("users").doc(parentUserId).get();

        if (!ownerDoc.exists) {
          logger.error(`Owner user ${parentUserId} not found`);
          return null;
        }

        const ownerData = ownerDoc.data();
        const fcmToken = ownerData.fcmToken;

        if (!fcmToken) {
          logger.log(`Owner ${parentUserId} has no FCM token`);
          return null;
        }

        const childDoc = await db.collection("users").doc(childUserId).get();
        const childName = childDoc.exists ? (childDoc.data().name || "Someone") : "Someone";

        const message = {
          token: fcmToken,
          notification: {
            title: "🎉 Your Referral Code Was Used!",
            body: `${childName} just used your referral code. You're building your chain!`,
          },
          data: {
            type: "referral_used",
            referralCodeId: referralCodeId,
            childUserId: childUserId,
          },
          android: {
            priority: "high",
            notification: {
              sound: "default",
              color: "#00D9FF",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        };

        await fcm.send(message);
        logger.info(`Notification sent to ${parentUserId} about referral use by ${childUserId}`);

        return null;
      } catch (error) {
        logger.error("Error sending referral notification:", error);
        return null;
      }
    },
);

// ============================================================================
// ENGAGEMENT METRICS - Increment Contest Clicks
// ============================================================================
exports.incrementContestClicks = onCall(async (request) => {
  if (!request.auth) {
    throw new Error("unauthenticated: User must be authenticated");
  }

  const {contestId} = request.data;
  const userId = request.auth.uid;

  if (!contestId) {
    throw new Error("invalid-argument: contestId is required");
  }

  try {
    const recentClickRef = db.collection("userActivity")
        .doc(userId)
        .collection("contestClicks")
        .doc(contestId);

    const recentClick = await recentClickRef.get();
    const now = Timestamp.now();

    if (recentClick.exists) {
      const lastClick = recentClick.data().timestamp;
      const timeDiff = now.seconds - lastClick.seconds;

      if (timeDiff < 5) {
        throw new Error("resource-exhausted: Please wait before clicking again");
      }
    }

    await db.collection("contests").doc(contestId).update({
      clicks: FieldValue.increment(1),
    });

    await recentClickRef.set({
      timestamp: now,
    });

    return {success: true, message: "Click recorded"};
  } catch (error) {
    logger.error("Error incrementing clicks:", error);
    throw error;
  }
});

// ============================================================================
// ENGAGEMENT METRICS - Toggle Contest Like
// ============================================================================
exports.toggleContestLike = onCall(async (request) => {
  if (!request.auth) {
    throw new Error("unauthenticated: User must be authenticated");
  }

  const {contestId} = request.data;
  const userId = request.auth.uid;

  if (!contestId) {
    throw new Error("invalid-argument: contestId is required");
  }

  try {
    const userRef = db.collection("users").doc(userId);
    const contestRef = db.collection("contests").doc(contestId);

    const result = await db.runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);
      const likedContests = userDoc.data()?.likedContests || [];

      const isLiked = likedContests.includes(contestId);

      if (isLiked) {
        transaction.update(userRef, {
          likedContests: FieldValue.arrayRemove(contestId),
        });
        transaction.update(contestRef, {
          likes: FieldValue.increment(-1),
        });
        return {liked: false};
      } else {
        transaction.update(userRef, {
          likedContests: FieldValue.arrayUnion(contestId),
        });
        transaction.update(contestRef, {
          likes: FieldValue.increment(1),
        });
        return {liked: true};
      }
    });

    return {success: true, ...result};
  } catch (error) {
    logger.error("Error toggling like:", error);
    throw error;
  }
});

// ============================================================================
// ENGAGEMENT METRICS - Toggle Contest Save/Bookmark
// ============================================================================
exports.toggleContestSave = onCall(async (request) => {
  if (!request.auth) {
    throw new Error("unauthenticated: User must be authenticated");
  }

  const {contestId} = request.data;
  const userId = request.auth.uid;

  if (!contestId) {
    throw new Error("invalid-argument: contestId is required");
  }

  try {
    const userRef = db.collection("users").doc(userId);
    const contestRef = db.collection("contests").doc(contestId);

    const result = await db.runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);
      const savedContests = userDoc.data()?.savedContests || [];

      const isSaved = savedContests.includes(contestId);

      if (isSaved) {
        transaction.update(userRef, {
          savedContests: FieldValue.arrayRemove(contestId),
        });
        transaction.update(contestRef, {
          saves: FieldValue.increment(-1),
        });
        return {saved: false};
      } else {
        transaction.update(userRef, {
          savedContests: FieldValue.arrayUnion(contestId),
        });
        transaction.update(contestRef, {
          saves: FieldValue.increment(1),
        });
        return {saved: true};
      }
    });

    return {success: true, ...result};
  } catch (error) {
    logger.error("Error toggling save:", error);
    throw error;
  }
});

// ============================================================================
// HOT BADGE CALCULATION
// Scheduled function runs every hour
// ============================================================================
exports.calculateHotContests = onSchedule("every 1 hours", async (event) => {
  try {
    const now = Timestamp.now();
    const contestsSnapshot = await db.collection("contests").get();

    const updates = [];

    for (const doc of contestsSnapshot.docs) {
      const contest = doc.data();
      const contestId = doc.id;

      const clicks = contest.clicks || 0;
      const likes = contest.likes || 0;
      const saves = contest.saves || 0;

      const commentsSnapshot = await db
          .collection("sweepstakes")
          .doc(contestId)
          .collection("comments")
          .get();
      const commentCount = commentsSnapshot.size;

      // Hotness formula: clicks + (likes * 3) + (saves * 5) + (comments * 2)
      const hotnessScore = clicks + (likes * 3) + (saves * 5) + (commentCount * 2);
      const shouldBeHot = hotnessScore > 50;

      if (contest.isHot !== shouldBeHot) {
        updates.push(
            db.collection("contests").doc(contestId).update({
              isHot: shouldBeHot,
              hotnessScore: hotnessScore,
              hotnessUpdatedAt: now,
            }),
        );
      }
    }

    await Promise.all(updates);
    logger.info(`Updated HOT status for ${updates.length} contests`);
    return null;
  } catch (error) {
    logger.error("Error calculating hot contests:", error);
    return null;
  }
});

// ============================================================================
// RATE LIMITING - Check and enforce limits
// ============================================================================
exports.checkRateLimit = onCall(async (request) => {
  if (!request.auth) {
    throw new Error("unauthenticated: User must be authenticated");
  }

  const {action} = request.data;
  const userId = request.auth.uid;

  const rateLimits = {
    comment: {limit: 10, windowMinutes: 60},
    referralCode: {limit: 3, windowMinutes: 1440},
    report: {limit: 5, windowMinutes: 60},
  };

  const config = rateLimits[action];
  if (!config) {
    throw new Error("invalid-argument: Invalid action");
  }

  try {
    const now = Timestamp.now();
    const windowStart = new Date(now.toDate());
    windowStart.setMinutes(windowStart.getMinutes() - config.windowMinutes);

    const actionsRef = db.collection("userActivity")
        .doc(userId)
        .collection(action + "s")
        .where("timestamp", ">", Timestamp.fromDate(windowStart));

    const actionsSnapshot = await actionsRef.get();
    const actionCount = actionsSnapshot.size;

    if (actionCount >= config.limit) {
      throw new Error(
          `resource-exhausted: Rate limit exceeded. You can only perform ${config.limit} ${action}s per ${config.windowMinutes} minutes.`,
      );
    }

    await db.collection("userActivity")
        .doc(userId)
        .collection(action + "s")
        .add({
          timestamp: now,
        });

    return {allowed: true, remaining: config.limit - actionCount - 1};
  } catch (error) {
    logger.error("Error checking rate limit:", error);
    throw error;
  }
});

// ============================================================================
// PRODUCTION MONITORING FUNCTIONS
// ============================================================================

/**
 * Health check endpoint for immediate system status
 */
exports.healthCheck = onCall(async (request) => {
  try {
    const now = Timestamp.now();
    const fiveMinutesAgo = Timestamp.fromMillis(now.toMillis() - 5 * 60 * 1000);
    
    // Check database connectivity
    await db.collection("health_check").doc("test").get();
    const dbConnected = true; // If we get here, DB is connected
    
    // Check recent activity
    const recentUsersSnapshot = await db.collection("users")
      .where("lastActive", ">", fiveMinutesAgo)
      .limit(1)
      .get();
    
    const hasRecentActivity = !recentUsersSnapshot.empty;
    
    // Check for recent errors
    const recentErrorsSnapshot = await db.collection("error_logs")
      .where("timestamp", ">", fiveMinutesAgo)
      .get();
    
    const recentErrorCount = recentErrorsSnapshot.size;
    
    const health = {
      timestamp: now,
      status: dbConnected && recentErrorCount < 5 ? "healthy" : "degraded",
      database: {
        connected: dbConnected,
        responsive: true
      },
      activity: {
        hasRecentUsers: hasRecentActivity,
        recentErrors: recentErrorCount
      },
      functions: {
        responsive: true,
        memoryUsage: process.memoryUsage()
      }
    };
    
    return health;
    
  } catch (error) {
    logger.error("Health check failed:", error);
    return {
      timestamp: Timestamp.now(),
      status: "unhealthy",
      error: error.message
    };
  }
});

/**
 * Monitor Firestore quota usage
 * Runs every hour to track usage patterns
 */
exports.monitorFirestoreQuota = onSchedule("every 1 hours", async () => {
  try {
    logger.info("Starting Firestore quota monitoring...");
    
    const now = Timestamp.now();
    const oneHourAgo = Timestamp.fromMillis(now.toMillis() - 60 * 60 * 1000);
    
    // Track active users
    const activeUsersSnapshot = await db.collection("users")
      .where("lastActive", ">", oneHourAgo)
      .get();
    const activeUserCount = activeUsersSnapshot.size;
    
    // Track contest interactions
    const contestsSnapshot = await db.collection("contests")
      .where("lastClicked", ">", oneHourAgo)
      .get();
    const hotContests = contestsSnapshot.size;
    
    const metrics = {
      timestamp: now,
      activeUsers: activeUserCount,
      hotContests: hotContests,
      memoryUsage: process.memoryUsage(),
    };
    
    // Store metrics
    await db.collection("system_metrics").doc(`hourly_${now.toMillis()}`).set(metrics);
    
    logger.info(`Quota monitoring completed. Active Users: ${activeUserCount}, Hot Contests: ${hotContests}`);
    
    // Alert if unusually high activity
    if (activeUserCount > 1000) {
      logger.warn(`HIGH ACTIVITY: ${activeUserCount} active users in last hour`);
      
      await db.collection("alerts").add({
        title: "HIGH ACTIVITY DETECTED",
        message: `${activeUserCount} active users in the last hour`,
        priority: "medium",
        timestamp: now,
        sent: true
      });
    }
    
  } catch (error) {
    logger.error("Error in Firestore quota monitoring:", error);
  }
});

/**
 * Log error with context for monitoring
 */
exports.logError = onCall(async (request) => {
  try {
    const {error, context, userId} = request.data;
    
    await db.collection("error_logs").add({
      error,
      context,
      userId: userId || request.auth?.uid || "anonymous",
      timestamp: Timestamp.now(),
      userAgent: "unknown"
    });
    
    return {success: true};
    
  } catch (e) {
    logger.error("Error logging error:", e);
    throw new Error("Failed to log error");
  }
});

// ============================================================================
// DAILY CHALLENGES FUNCTIONS
// ============================================================================
const dailyChallenges = require("./reset-daily-challenges");
exports.resetDailyChallenges = dailyChallenges.resetDailyChallenges;
exports.manualResetDailyChallenges = dailyChallenges.manualResetDailyChallenges;

// ============================================================================
// PURCHASE VERIFICATION FUNCTIONS
// ============================================================================
const purchaseVerification = require("./verify-purchase");
exports.verifyPurchase = purchaseVerification.verifyPurchase;
exports.checkSubscriptionExpiry = purchaseVerification.checkSubscriptionExpiry;
exports.handleGooglePlayNotification = purchaseVerification.handleGooglePlayNotification;
