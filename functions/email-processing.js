const {onRequest} = require("firebase-functions/v2/https");
const {logger} = require("firebase-functions/v2");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, Timestamp} = require("firebase-admin/firestore");
const mailgun = require('mailgun-js');
const crypto = require('crypto');
const { sendPushNotification } = require('./notifications');

initializeApp();
const db = getFirestore();

// Mailgun configuration - uses environment variables
const mailgunApiKey = process.env.MAILGUN_API_KEY || 'YOUR_MAILGUN_API_KEY';
const mailgunDomain = process.env.MAILGUN_DOMAIN || 'sweepfeed.app';

// Note: Mailgun client is only needed for sending emails, not receiving
// For receiving, Mailgun sends webhooks to this function
const mg = mailgunApiKey !== 'YOUR_MAILGUN_API_KEY' 
    ? mailgun({apiKey: mailgunApiKey, domain: mailgunDomain})
    : null;

/**
 * Analyzes the email content to determine its category.
 * @param {object} emailData The email data.
 * @returns {string} The category of the email.
 */
function analyzeEmailCategory(emailData) {
    const subject = emailData.subject.toLowerCase();
    const body = emailData.body.toLowerCase();
    const sender = emailData.from.toLowerCase();

    // Winner email patterns
    const winnerPatterns = [
        'congratulations', 'you won', 'you\'re a winner', 'winner', 'prize',
        'you have won', 'claiming your prize', 'prize notification',
        'sweepstakes winner', 'contest winner', 'lucky winner', 'grand prize',
        'first place', 'winning entry',
    ];

    // Coupon email patterns
    const couponPatterns = [
        'coupon', 'discount code', 'promo code', 'voucher', 'save ',
        '% off', 'gift card', 'claim your code', 'exclusive deal',
    ];

    // Check for winner patterns first (higher priority)
    for (const pattern of winnerPatterns) {
        if (subject.includes(pattern) || body.includes(pattern)) {
            return 'winner';
        }
    }

    // Check for coupon patterns
    for (const pattern of couponPatterns) {
        if (subject.includes(pattern) || body.includes(pattern)) {
            return 'coupon';
        }
    }

    return 'general';
}


exports.processIncomingEmail = onRequest(async (req, res) => {
    if (req.method !== 'POST') {
        res.status(405).send('Method Not Allowed');
        return;
    }

    try {
        const { timestamp, token, signature } = req.body;

        // Verify webhook signature
        const hmac = crypto.createHmac('sha256', mailgunApiKey);
        const calculatedSignature = hmac.update(timestamp + token).digest('hex');

        if (calculatedSignature !== signature) {
            console.error('Invalid Mailgun webhook signature');
            res.status(401).send('Invalid signature');
            return;
        }

        // Optional: Check if the timestamp is recent to prevent replay attacks
        const timeDiff = Math.abs(Date.now() / 1000 - timestamp);
        if (timeDiff > 300) { // 5 minutes
            console.error('Mailgun webhook timestamp too old');
            res.status(401).send('Timestamp too old');
            return;
        }

        const recipient = req.body.recipient;
        const sender = req.body.sender;
        const subject = req.body.subject;
        const body = req.body['body-plain'] || req.body['body-html'] || '';

        // Extract the username from the recipient email
        const username = recipient.split('@')[0];

        // Find the user with this sweepfeed email address
        const userQuery = await db.collection('users').where('sweepFeedEmail', '==', recipient).limit(1).get();

        if (userQuery.empty) {
            console.warn(`No user found for email: ${recipient}`);
            res.status(404).send('User not found');
            return;
        }

        const userDoc = userQuery.docs[0];
        const userId = userDoc.id;

        const emailData = {
            from: sender,
            subject: subject,
            body: body,
            timestamp: Timestamp.now(),
            isRead: false,
            category: 'general', // Default category
        };

        // Implement email categorization logic here
        emailData.category = analyzeEmailCategory(emailData);

        // Save the email to the user's subcollection
        const emailDoc = await db.collection('users').doc(userId).collection('emails').add(emailData);
        emailData.id = emailDoc.id;


        // Trigger a push notification for winner/coupon emails
        if (emailData.category === 'winner' || emailData.category === 'coupon') {
            await sendPushNotification(userId, emailData);
        }

        res.status(200).send('Email processed successfully');
    } catch (error) {
        console.error('Error processing incoming email:', error);
        res.status(500).send('Internal Server Error');
    }
});
