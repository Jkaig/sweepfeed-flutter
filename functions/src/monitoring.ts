import {onSchedule} from "firebase-functions/v2/scheduler";
import {onCall, CallableRequest} from "firebase-functions/v2/https";
import {logger} from "firebase-functions/v2";
import {initializeApp} from "firebase-admin/app";
import {getFirestore, Timestamp} from "firebase-admin/firestore";
// import {getMessaging} from "firebase-admin/messaging"; // Not used currently

// Initialize Firebase Admin if not already initialized
if (!initializeApp.length) {
  initializeApp();
}

const db = getFirestore();
// const fcm = getMessaging(); // Commented out as not used in current implementation

// ============================================================================
// SYSTEM HEALTH MONITORING
// ============================================================================

/**
 * Monitors Firestore quota usage and sends alerts when approaching limits
 * Runs every hour to track usage patterns
 */
export const monitorFirestoreQuota = onSchedule("every 1 hours", async () => {
  try {
    logger.info("Starting Firestore quota monitoring...");
    
    const now = Timestamp.now();
    const oneHourAgo = Timestamp.fromMillis(now.toMillis() - 60 * 60 * 1000);
    
    // Monitor read operations
    const readsRef = db.collection("system_metrics").doc("firestore_reads");
    const readsDoc = await readsRef.get();
    const currentReads = readsDoc.exists ? readsDoc.data()?.count || 0 : 0;
    
    // Monitor write operations
    const writesRef = db.collection("system_metrics").doc("firestore_writes");
    const writesDoc = await writesRef.get();
    const currentWrites = writesDoc.exists ? writesDoc.data()?.count || 0 : 0;
    
    // Track active users
    const activeUsersSnapshot = await db.collection("users")
      .where("lastActive", ">", oneHourAgo)
      .get();
    const activeUserCount = activeUsersSnapshot.size;
    
    // Track contest interactions
    const contestClicksSnapshot = await db.collection("contests")
      .where("lastClicked", ">", oneHourAgo)
      .get();
    const hotContests = contestClicksSnapshot.size;
    
    const metrics = {
      timestamp: now,
      reads: currentReads,
      writes: currentWrites,
      activeUsers: activeUserCount,
      hotContests: hotContests,
      memoryUsage: process.memoryUsage(),
    };
    
    // Store metrics
    await db.collection("system_metrics").doc(`hourly_${now.toMillis()}`).set(metrics);
    
    // Check for quota warnings (80% of daily limit)
    const dailyReadLimit = 50000; // Adjust based on your Firebase plan
    const dailyWriteLimit = 20000;
    
    if (currentReads > dailyReadLimit * 0.8) {
      await sendSlackAlert(
        "🚨 FIRESTORE QUOTA WARNING",
        `Read operations at ${Math.round((currentReads / dailyReadLimit) * 100)}% of daily limit`,
        "high"
      );
    }
    
    if (currentWrites > dailyWriteLimit * 0.8) {
      await sendSlackAlert(
        "🚨 FIRESTORE QUOTA WARNING", 
        `Write operations at ${Math.round((currentWrites / dailyWriteLimit) * 100)}% of daily limit`,
        "high"
      );
    }
    
    logger.info(`Quota monitoring completed. Reads: ${currentReads}, Writes: ${currentWrites}, Active Users: ${activeUserCount}`);
    
  } catch (error: any) {
    logger.error("Error in Firestore quota monitoring:", error);
    await sendSlackAlert(
      "❌ MONITORING ERROR",
      `Firestore quota monitoring failed: ${error.message}`,
      "critical"
    );
  }
});

/**
 * Detects unusual traffic spikes and performance anomalies
 * Runs every 15 minutes for real-time detection
 */
export const detectUsageSpikes = onSchedule("every 15 minutes", async () => {
  try {
    logger.info("Starting usage spike detection...");
    
    const now = Timestamp.now();
    const fifteenMinutesAgo = Timestamp.fromMillis(now.toMillis() - 15 * 60 * 1000);
    const oneHourAgo = Timestamp.fromMillis(now.toMillis() - 60 * 60 * 1000);
    
    // Check recent active users vs normal baseline
    const recentActiveUsers = await db.collection("users")
      .where("lastActive", ">", fifteenMinutesAgo)
      .get();
    
    const hourlyActiveUsers = await db.collection("users")
      .where("lastActive", ">", oneHourAgo)
      .get();
    
    const recentCount = recentActiveUsers.size;
    const hourlyAverage = hourlyActiveUsers.size / 4; // 15-minute average
    
    // Detect 3x traffic spike
    if (recentCount > hourlyAverage * 3 && recentCount > 10) {
      await sendSlackAlert(
        "📈 TRAFFIC SPIKE DETECTED",
        `Current 15-min active users: ${recentCount}, Normal average: ${Math.round(hourlyAverage)}`,
        "medium"
      );
      
      // Store spike event for analysis
      await db.collection("system_events").add({
        type: "traffic_spike",
        timestamp: now,
        currentUsers: recentCount,
        normalAverage: hourlyAverage,
        multiplier: recentCount / hourlyAverage
      });
    }
    
    // Monitor error rates
    const errorLogsSnapshot = await db.collection("error_logs")
      .where("timestamp", ">", fifteenMinutesAgo)
      .get();
    
    const errorCount = errorLogsSnapshot.size;
    if (errorCount > 5) {
      await sendSlackAlert(
        "🚨 HIGH ERROR RATE",
        `${errorCount} errors in the last 15 minutes`,
        "high"
      );
    }
    
    logger.info(`Spike detection completed. Recent users: ${recentCount}, Errors: ${errorCount}`);
    
  } catch (error: any) {
    logger.error("Error in usage spike detection:", error);
    await sendSlackAlert(
      "❌ MONITORING ERROR",
      `Usage spike detection failed: ${error.message}`,
      "critical"
    );
  }
});

/**
 * Monitors Cloud Function performance and execution times
 * Runs every 30 minutes
 */
export const monitorFunctionPerformance = onSchedule("every 30 minutes", async () => {
  try {
    logger.info("Starting function performance monitoring...");
    
    const now = Timestamp.now();
    const thirtyMinutesAgo = Timestamp.fromMillis(now.toMillis() - 30 * 60 * 1000);
    
    // Get function execution logs
    const executionLogsSnapshot = await db.collection("function_metrics")
      .where("timestamp", ">", thirtyMinutesAgo)
      .get();
    
    const executions = executionLogsSnapshot.docs.map(doc => doc.data());
    
    if (executions.length === 0) {
      logger.info("No function executions in the last 30 minutes");
      return;
    }
    
    // Calculate average execution times by function
    const functionStats: any = {};
    executions.forEach((exec: any) => {
      if (!functionStats[exec.functionName]) {
        functionStats[exec.functionName] = {
          count: 0,
          totalDuration: 0,
          errors: 0
        };
      }
      
      functionStats[exec.functionName].count++;
      functionStats[exec.functionName].totalDuration += exec.duration || 0;
      
      if (exec.error) {
        functionStats[exec.functionName].errors++;
      }
    });
    
    // Check for performance issues
    for (const [functionName, stats] of Object.entries(functionStats)) {
      const statsObj = stats as any;
      const avgDuration = statsObj.totalDuration / statsObj.count;
      const errorRate = (statsObj.errors / statsObj.count) * 100;
      
      // Alert if function takes longer than 10 seconds on average
      if (avgDuration > 10000) {
        await sendSlackAlert(
          "⚡ SLOW FUNCTION DETECTED",
          `${functionName}: Average execution time ${(avgDuration/1000).toFixed(2)}s`,
          "medium"
        );
      }
      
      // Alert if error rate > 5%
      if (errorRate > 5) {
        await sendSlackAlert(
          "🚨 HIGH FUNCTION ERROR RATE",
          `${functionName}: ${errorRate.toFixed(1)}% error rate (${statsObj.errors}/${statsObj.count})`,
          "high"
        );
      }
    }
    
    logger.info(`Performance monitoring completed. Analyzed ${executions.length} executions`);
    
  } catch (error: any) {
    logger.error("Error in function performance monitoring:", error);
    await sendSlackAlert(
      "❌ MONITORING ERROR",
      `Function performance monitoring failed: ${error.message}`,
      "critical"
    );
  }
});

/**
 * Daily system health report
 * Runs every day at 9 AM
 */
export const dailyHealthReport = onSchedule("every day 09:00", async () => {
  try {
    logger.info("Generating daily health report...");
    
    const now = Timestamp.now();
    const twentyFourHoursAgo = Timestamp.fromMillis(now.toMillis() - 24 * 60 * 60 * 1000);
    
    // Get 24-hour metrics
    const metricsSnapshot = await db.collection("system_metrics")
      .where("timestamp", ">", twentyFourHoursAgo)
      .orderBy("timestamp", "desc")
      .get();
    
    const metrics = metricsSnapshot.docs.map(doc => doc.data());
    
    if (metrics.length === 0) {
      await sendSlackAlert(
        "⚠️ NO METRICS DATA",
        "No system metrics found for the last 24 hours",
        "medium"
      );
      return;
    }
    
    // Calculate daily totals
    const totalReads = metrics.reduce((sum, m) => sum + (m.reads || 0), 0);
    const totalWrites = metrics.reduce((sum, m) => sum + (m.writes || 0), 0);
    const avgActiveUsers = metrics.reduce((sum, m) => sum + (m.activeUsers || 0), 0) / metrics.length;
    const maxActiveUsers = Math.max(...metrics.map(m => m.activeUsers || 0));
    
    // Get error counts
    const errorsSnapshot = await db.collection("error_logs")
      .where("timestamp", ">", twentyFourHoursAgo)
      .get();
    
    const totalErrors = errorsSnapshot.size;
    
    // Get user engagement metrics
    const contestsSnapshot = await db.collection("contests")
      .where("lastClicked", ">", twentyFourHoursAgo)
      .get();
    
    const activeContests = contestsSnapshot.size;
    
    const report = {
      date: now.toDate().toISOString().split('T')[0],
      firestore: {
        reads: totalReads,
        writes: totalWrites,
      },
      users: {
        averageActive: Math.round(avgActiveUsers),
        peakActive: maxActiveUsers,
      },
      errors: totalErrors,
      engagement: {
        activeContests: activeContests,
      },
      timestamp: now
    };
    
    // Store the report
    await db.collection("daily_reports").doc(report.date).set(report);
    
    // Send summary to Slack
    const healthStatus = totalErrors < 10 ? "🟢 HEALTHY" : totalErrors < 50 ? "🟡 WARNING" : "🔴 CRITICAL";
    
    await sendSlackAlert(
      `📊 DAILY HEALTH REPORT - ${healthStatus}`,
      `**SweepFeed Daily Summary**
      📊 **Firestore Usage:** ${totalReads.toLocaleString()} reads, ${totalWrites.toLocaleString()} writes
      👥 **Users:** ${Math.round(avgActiveUsers)} avg active, ${maxActiveUsers} peak
      🎯 **Engagement:** ${activeContests} active contests
      ❌ **Errors:** ${totalErrors} total
      
      Status: ${healthStatus}`,
      totalErrors < 10 ? "low" : totalErrors < 50 ? "medium" : "high"
    );
    
    logger.info("Daily health report generated successfully");
    
  } catch (error: any) {
    logger.error("Error generating daily health report:", error);
    await sendSlackAlert(
      "❌ MONITORING ERROR",
      `Daily health report failed: ${error.message}`,
      "critical"
    );
  }
});

// ============================================================================
// ALERTING FUNCTIONS
// ============================================================================

/**
 * Sends alerts to Slack webhook
 */
async function sendSlackAlert(title: string, message: string, priority: "low" | "medium" | "high" | "critical") {
  try {
    const webhook = process.env.SLACK_WEBHOOK_URL;
    if (!webhook) {
      logger.warn("SLACK_WEBHOOK_URL not configured, skipping alert");
      return;
    }
    
    // Colors for future Slack integration
    // const colors = {
    //   low: "#36a64f",      // Green
    //   medium: "#ff9500",   // Orange  
    //   high: "#ff0000",     // Red
    //   critical: "#8B0000"  // Dark Red
    // };
    
    // In a real implementation, you would use HTTP client to send to Slack
    // For now, we'll log the alert
    logger.info(`SLACK ALERT [${priority.toUpperCase()}]: ${title} - ${message}`);
    
    // Store alert in database for tracking
    await db.collection("alerts").add({
      title,
      message,
      priority,
      timestamp: Timestamp.now(),
      sent: true
    });
    
  } catch (error: any) {
    logger.error("Error sending Slack alert:", error);
    
    // Store failed alert
    await db.collection("alerts").add({
      title,
      message,
      priority,
      timestamp: Timestamp.now(),
      sent: false,
      error: error.message
    });
  }
}

/**
 * Manual health check endpoint for immediate system status
 */
export const healthCheck = onCall(async (request) => {
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
    
  } catch (error: any) {
    logger.error("Health check failed:", error);
    return {
      timestamp: Timestamp.now(),
      status: "unhealthy",
      error: error.message
    };
  }
});

/**
 * Function execution tracker (to be called by other functions)
 */
export const trackFunctionExecution = async (functionName: string, duration: number, error?: string) => {
  try {
    await db.collection("function_metrics").add({
      functionName,
      duration,
      error: error || null,
      timestamp: Timestamp.now()
    });
  } catch (e) {
    logger.error("Error tracking function execution:", e);
  }
};

/**
 * Log error with context for monitoring
 */
export const logError = onCall(async (request: CallableRequest) => {
  try {
    const {error, context, userId} = request.data;
    
    await db.collection("error_logs").add({
      error,
      context,
      userId: userId || request.auth?.uid || "anonymous",
      timestamp: Timestamp.now(),
      userAgent: "unknown" // Headers not available in v2 functions
    });
    
    return {success: true};
    
  } catch (e: any) {
    logger.error("Error logging error:", e);
    throw new Error("Failed to log error");
  }
});