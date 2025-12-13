"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getVipNotificationStats = exports.processScheduledNotifications = exports.onContestCreated = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const HIGH_VALUE_THRESHOLD = 500;
const ULTRA_HIGH_VALUE_THRESHOLD = 5000;
const PREMIUM_EARLY_ACCESS_HOURS = 12;
exports.onContestCreated = functions.firestore
    .document('contests/{contestId}')
    .onCreate(async (snap, context) => {
    try {
        const contest = snap.data();
        const contestId = context.params.contestId;
        const prizeValue = parseFloat(contest.prizeValue) || 0;
        if (prizeValue < HIGH_VALUE_THRESHOLD) {
            console.log(`Contest ${contestId} not high-value enough: $${prizeValue}`);
            return null;
        }
        console.log(`🔥 HIGH-VALUE CONTEST DETECTED: ${contest.title} - $${prizeValue}`);
        await admin.firestore().collection('high_value_sweepstakes').doc(contestId).set({
            title: contest.title,
            prizeValue: prizeValue,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            endDate: contest.endDate,
            category: contest.category || 'general',
            vipNotificationSent: false,
            vipNotificationTime: null,
            publicNotificationTime: null,
        });
        await sendVipInstantNotifications(contestId, contest, prizeValue);
        if (prizeValue >= ULTRA_HIGH_VALUE_THRESHOLD) {
            await schedulePremiumNotifications(contestId, contest, prizeValue);
        }
        return null;
    }
    catch (error) {
        console.error('Error in onContestCreated:', error);
        return null;
    }
});
async function sendVipInstantNotifications(contestId, contest, prizeValue) {
    try {
        const vipUsersSnapshot = await admin.firestore()
            .collection('users')
            .where('tier', '==', 'vip')
            .get();
        console.log(`Found ${vipUsersSnapshot.size} VIP users`);
        let sentCount = 0;
        for (const userDoc of vipUsersSnapshot.docs) {
            const userData = userDoc.data();
            const notificationSettings = userData.notificationSettings || {};
            const pushSettings = notificationSettings.push || {};
            const pushTypes = pushSettings.types || {};
            if (!pushSettings.enabled || !pushTypes.highValue) {
                console.log(`VIP user ${userDoc.id} has high-value notifications disabled`);
                continue;
            }
            const interests = userData.interests || [];
            if (interests.length > 0 && !interests.includes(contest.category)) {
                console.log(`VIP user ${userDoc.id} not interested in category: ${contest.category}`);
                continue;
            }
            const fcmToken = userData.fcmToken;
            if (!fcmToken) {
                console.log(`VIP user ${userDoc.id} has no FCM token`);
                continue;
            }
            const message = {
                token: fcmToken,
                notification: {
                    title: `🔥 VIP EXCLUSIVE: ${contest.title}`,
                    body: `WIN $${prizeValue.toFixed(0)}! You have 24-hour early access`,
                },
                data: {
                    type: 'vip_high_value',
                    sweepstake_id: contestId,
                    prize_value: prizeValue.toString(),
                    early_access: 'true',
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                },
                android: {
                    priority: 'high',
                    notification: {
                        channelId: 'high_value_alerts',
                        priority: 'max',
                        sound: 'vip_notification',
                        color: '#FFD700',
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            sound: 'vip_notification.wav',
                            badge: 1,
                            contentAvailable: true,
                        },
                    },
                },
            };
            try {
                await admin.messaging().send(message);
                await admin.firestore()
                    .collection('users')
                    .doc(userDoc.id)
                    .collection('notification_history')
                    .add({
                    sweepstakeId: contestId,
                    type: 'vip_high_value',
                    sentAt: admin.firestore.FieldValue.serverTimestamp(),
                    title: message.notification.title,
                    body: message.notification.body,
                });
                sentCount++;
                console.log(`✅ VIP notification sent to user: ${userDoc.id}`);
            }
            catch (sendError) {
                console.error(`Error sending to VIP user ${userDoc.id}:`, sendError);
            }
        }
        await admin.firestore()
            .collection('high_value_sweepstakes')
            .doc(contestId)
            .update({
            vipNotificationSent: true,
            vipNotificationTime: admin.firestore.FieldValue.serverTimestamp(),
            vipNotificationCount: sentCount,
        });
        console.log(`📊 VIP notifications sent: ${sentCount}`);
    }
    catch (error) {
        console.error('Error sending VIP notifications:', error);
    }
}
async function schedulePremiumNotifications(contestId, contest, prizeValue) {
    try {
        const scheduleTime = Date.now() + (PREMIUM_EARLY_ACCESS_HOURS * 60 * 60 * 1000);
        await admin.firestore().collection('scheduled_notifications').add({
            type: 'premium_high_value',
            contestId: contestId,
            contestTitle: contest.title,
            prizeValue: prizeValue,
            category: contest.category,
            scheduledFor: new Date(scheduleTime),
            status: 'pending',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`⏰ Premium notifications scheduled for ${PREMIUM_EARLY_ACCESS_HOURS} hours from now`);
    }
    catch (error) {
        console.error('Error scheduling Premium notifications:', error);
    }
}
exports.processScheduledNotifications = functions.pubsub
    .schedule('every 1 hours')
    .onRun(async (context) => {
    try {
        const now = new Date();
        const scheduledSnapshot = await admin.firestore()
            .collection('scheduled_notifications')
            .where('status', '==', 'pending')
            .where('scheduledFor', '<=', now)
            .get();
        console.log(`Found ${scheduledSnapshot.size} scheduled notifications to process`);
        for (const doc of scheduledSnapshot.docs) {
            const notification = doc.data();
            if (notification.type === 'premium_high_value') {
                await sendPremiumNotifications(notification.contestId, notification.contestTitle, notification.prizeValue, notification.category);
                await doc.ref.update({
                    status: 'sent',
                    sentAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }
        }
        return null;
    }
    catch (error) {
        console.error('Error processing scheduled notifications:', error);
        return null;
    }
});
async function sendPremiumNotifications(contestId, contestTitle, prizeValue, category) {
    try {
        const premiumUsersSnapshot = await admin.firestore()
            .collection('users')
            .where('tier', '==', 'premium')
            .get();
        console.log(`Found ${premiumUsersSnapshot.size} Premium users`);
        let sentCount = 0;
        for (const userDoc of premiumUsersSnapshot.docs) {
            const userData = userDoc.data();
            if (userData.premiumUntil) {
                const premiumUntil = userData.premiumUntil.toDate();
                if (premiumUntil <= new Date()) {
                    console.log(`User ${userDoc.id} premium expired`);
                    continue;
                }
            }
            const notificationSettings = userData.notificationSettings || {};
            const pushSettings = notificationSettings.push || {};
            const pushTypes = pushSettings.types || {};
            if (!pushSettings.enabled || !pushTypes.highValue) {
                continue;
            }
            const interests = userData.interests || [];
            if (interests.length > 0 && !interests.includes(category)) {
                continue;
            }
            const fcmToken = userData.fcmToken;
            if (!fcmToken)
                continue;
            const message = {
                token: fcmToken,
                notification: {
                    title: `⭐ Premium Alert: ${contestTitle}`,
                    body: `WIN $${prizeValue.toFixed(0)}! Premium early access`,
                },
                data: {
                    type: 'premium_high_value',
                    sweepstake_id: contestId,
                    prize_value: prizeValue.toString(),
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                },
                android: {
                    priority: 'high',
                    notification: {
                        channelId: 'high_value_alerts',
                        priority: 'high',
                        sound: 'premium_notification',
                        color: '#007AFF',
                    },
                },
            };
            try {
                await admin.messaging().send(message);
                await admin.firestore()
                    .collection('users')
                    .doc(userDoc.id)
                    .collection('notification_history')
                    .add({
                    sweepstakeId: contestId,
                    type: 'premium_high_value',
                    sentAt: admin.firestore.FieldValue.serverTimestamp(),
                    title: message.notification.title,
                    body: message.notification.body,
                });
                sentCount++;
            }
            catch (sendError) {
                console.error(`Error sending to Premium user ${userDoc.id}:`, sendError);
            }
        }
        await admin.firestore()
            .collection('high_value_sweepstakes')
            .doc(contestId)
            .update({
            premiumNotificationSent: true,
            premiumNotificationTime: admin.firestore.FieldValue.serverTimestamp(),
            premiumNotificationCount: sentCount,
        });
        console.log(`📊 Premium notifications sent: ${sentCount}`);
    }
    catch (error) {
        console.error('Error sending Premium notifications:', error);
    }
}
exports.getVipNotificationStats = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }
    try {
        const highValueSnapshot = await admin.firestore()
            .collection('high_value_sweepstakes')
            .where('vipNotificationSent', '==', true)
            .get();
        let totalValue = 0;
        let totalVipNotifications = 0;
        let last24Hours = 0;
        const cutoff = new Date(Date.now() - 24 * 60 * 60 * 1000);
        highValueSnapshot.docs.forEach(doc => {
            const data = doc.data();
            totalValue += data.prizeValue || 0;
            totalVipNotifications += data.vipNotificationCount || 0;
            if (data.vipNotificationTime && data.vipNotificationTime.toDate() > cutoff) {
                last24Hours++;
            }
        });
        return {
            totalHighValueSweepstakes: highValueSnapshot.size,
            averagePrizeValue: highValueSnapshot.size > 0 ? totalValue / highValueSnapshot.size : 0,
            totalVipNotifications,
            last24Hours,
        };
    }
    catch (error) {
        console.error('Error getting VIP stats:', error);
        throw new functions.https.HttpsError('internal', 'Error fetching stats');
    }
});
//# sourceMappingURL=vipNotifications.js.map