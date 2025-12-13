const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();
const fcm = getMessaging();

/**
 * Sends a push notification to a user.
 * @param {string} userId The ID of the user to send the notification to.
 * @param {object} emailData The data of the email that triggered the notification.
 */
async function sendPushNotification(userId, emailData) {
    try {
        const userDoc = await db.collection('users').doc(userId).get();
        const user = userDoc.data();

        if (user && user.fcmToken) {
            const payload = {
                notification: {
                    title: `You've got a new ${emailData.category} email!`,
                    body: emailData.subject,
                },
                data: {
                    type: emailData.category,
                    emailId: emailData.id,
                },
                token: user.fcmToken,
            };

            await fcm.send(payload);
            console.log(`Sent ${emailData.category} notification to user ${userId}`);
        }
    } catch (error) {
        console.error(`Error sending push notification to user ${userId}:`, error);
    }
}

module.exports = {
    sendPushNotification,
};
