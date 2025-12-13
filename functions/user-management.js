const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onCall} = require("firebase-functions/v2/https");
const {onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {logger} = require("firebase-functions/v2");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, Timestamp} = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

// ============================================================================
// ACCOUNT DELETION - GDPR/CCPA Compliant
// Scheduled function to permanently delete accounts after 7-day grace period
// Required for Apple App Store and Google Play Store compliance
// ============================================================================

/**
 * Process scheduled account deletions daily
 * Runs every day at 3:00 AM to process accounts marked for deletion
 */
exports.processScheduledDeletions = onSchedule(
    {
        schedule: '0 3 * * *',
        timeZone: 'America/New_York',
    },
    async (event) => {
        logger.info('Starting scheduled account deletion process...');

        const now = Timestamp.now();

        try {
            // Find users marked for deletion whose grace period has expired
            const usersToDelete = await db.collection('users')
                .where('markedForDeletion', '==', true)
                .where('deletionScheduledFor', '<=', now)
                .get();

            if (usersToDelete.empty) {
                console.log('No accounts to delete today');
                return null;
            }

            console.log(`Found ${usersToDelete.size} accounts to delete`);

            const deletionPromises = usersToDelete.docs.map(async (userDoc) => {
                const userId = userDoc.id;
                const userData = userDoc.data();

                try {
                    await deleteUserAccount(userId, userData);
                    console.log(`Successfully deleted account: ${userId}`);
                } catch (error) {
                    console.error(`Failed to delete account ${userId}:`, error);
                    // Log failure for manual review
                    await db.collection('deletion_failures').add({
                        userId,
                        error: error.message,
                        timestamp: now,
                        userData: { email: userData.email, createdAt: userData.createdAt }
                    });
                }
            });

            await Promise.all(deletionPromises);
            console.log('Account deletion process completed');
            return null;

        } catch (error) {
            console.error('Error in scheduled deletion process:', error);
            throw error;
        }
    });

/**
 * Delete all user data - GDPR Right to Erasure compliant
 */
async function deleteUserAccount(userId, userData) {
    const batch = db.batch();

    // 1. Delete user's subcollections
    const subcollections = [
        'enteredContests',
        'notifications',
        'activityLog',
        'savedContests',
        'comments',
        'referrals'
    ];

    for (const subcollection of subcollections) {
        const subcollectionRef = db.collection('users').doc(userId).collection(subcollection);
        const docs = await subcollectionRef.get();
        docs.forEach(doc => batch.delete(doc.ref));
    }

    // 2. Delete user activity data
    const userActivityRef = db.collection('userActivity').doc(userId);
    const activityDoc = await userActivityRef.get();
    if (activityDoc.exists) {
        // Delete nested collections in userActivity
        const activitySubcollections = ['contestClicks', 'comments', 'reports', 'referralCodes'];
        for (const subColl of activitySubcollections) {
            const activitySubDocs = await userActivityRef.collection(subColl).get();
            activitySubDocs.forEach(doc => batch.delete(doc.ref));
        }
        batch.delete(userActivityRef);
    }

    // 3. Delete user's referral codes
    const referralCodesSnapshot = await db.collection('referrals')
        .where('parentUserId', '==', userId)
        .get();
    referralCodesSnapshot.forEach(doc => batch.delete(doc.ref));

        // 4. Delete user's purchases (keep anonymized record for accounting)
        const purchasesSnapshot = await db.collection('purchases')
            .where('userId', '==', userId)
            .get();
        purchasesSnapshot.forEach(doc => {
            // Anonymize instead of delete for financial records
            batch.update(doc.ref, {
                userId: 'DELETED_USER',
                userEmail: null,
                anonymizedAt: Timestamp.now()
            });
        });

    // 5. Remove user from any contest entry lists (anonymize)
    const contestEntriesSnapshot = await db.collectionGroup('entries')
        .where('userId', '==', userId)
        .get();
    contestEntriesSnapshot.forEach(doc => {
        batch.update(doc.ref, {
            userId: 'DELETED_USER',
            userEmail: null,
            userName: 'Deleted User'
        });
    });

    // 6. Anonymize user's comments instead of deleting
    const commentsSnapshot = await db.collectionGroup('comments')
        .where('userId', '==', userId)
        .get();
    commentsSnapshot.forEach(doc => {
        batch.update(doc.ref, {
            userId: 'DELETED_USER',
            userName: 'Deleted User',
            userAvatar: null
        });
    });

        // 7. Log deletion for audit purposes (GDPR requires proof of deletion)
        const deletionLogRef = db.collection('deletion_logs').doc();
        batch.set(deletionLogRef, {
            userId,
            deletedAt: Timestamp.now(),
            userEmail: userData.email || null,
            accountCreatedAt: userData.createdAt || null,
            deletionRequestedAt: userData.deletionMarkedAt || null,
            signInProvider: userData.signInProvider || 'unknown',
            dataDeleted: [
                'user_document',
                'user_subcollections',
                'user_activity',
                'referral_codes',
                'purchases_anonymized',
                'contest_entries_anonymized',
                'comments_anonymized'
            ]
        });

    // 8. Delete the main user document
    batch.delete(db.collection('users').doc(userId));

    // Commit all Firestore changes
    await batch.commit();

        // 9. Delete Firebase Auth user (must be done after Firestore)
        try {
            const {getAuth} = require("firebase-admin/auth");
            const auth = getAuth();
            await auth.deleteUser(userId);
            logger.info(`Firebase Auth user ${userId} deleted`);
        } catch (authError) {
            // User might already be deleted from Auth
            if (authError.code !== 'auth/user-not-found') {
                throw authError;
            }
            logger.info(`Firebase Auth user ${userId} not found (already deleted)`);
        }

        // 10. Delete user files from Storage
        try {
            const {getStorage} = require("firebase-admin/storage");
            const storage = getStorage();
            const bucket = storage.bucket();
            await bucket.deleteFiles({
                prefix: `users/${userId}/`
            });
            logger.info(`Storage files for ${userId} deleted`);
        } catch (storageError) {
            // Storage might not have any files for this user
            logger.info(`No storage files found for ${userId} or error:`, storageError.message);
        }
}

/**
 * Cancel account deletion (user changed their mind)
 * Called when user logs back in during grace period
 */
exports.cancelAccountDeletion = onCall(async (request) => {
    if (!request.auth) {
        throw new Error('unauthenticated: Must be logged in');
    }

    const userId = context.auth.uid;

    try {
        const userRef = db.collection('users').doc(userId);
        const userDoc = await userRef.get();

        if (!userDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'User not found');
        }

        const userData = userDoc.data();
        if (!userData.markedForDeletion) {
            return { success: true, message: 'Account is not marked for deletion' };
        }

        await userRef.update({
            markedForDeletion: false,
            deletionScheduledFor: admin.firestore.FieldValue.delete(),
            deletionMarkedAt: admin.firestore.FieldValue.delete(),
            deletionCancelledAt: Timestamp.now()
        });

        logger.info(`Account deletion cancelled for user: ${userId}`);
        return { success: true, message: 'Account deletion cancelled successfully' };

    } catch (error) {
        logger.error('Error cancelling deletion:', error);
        throw new Error('internal: Failed to cancel deletion');
    }
});

/**
 * Immediate account deletion (for users who want instant deletion)
 * Bypasses grace period - use with caution
 */
exports.deleteAccountImmediately = onCall(async (request) => {
    if (!request.auth) {
        throw new Error('unauthenticated: Must be logged in');
    }

    const userId = request.auth.uid;
    const { confirmationCode } = request.data;

    // Require confirmation code to prevent accidental deletion
    if (confirmationCode !== 'DELETE_MY_ACCOUNT_PERMANENTLY') {
        throw new Error('invalid-argument: Invalid confirmation code');
    }

    try {
        const userDoc = await db.collection('users').doc(userId).get();
        if (!userDoc.exists) {
            throw new Error('not-found: User not found');
        }

        await deleteUserAccount(userId, userDoc.data());

        return { success: true, message: 'Account permanently deleted' };

    } catch (error) {
        logger.error('Error in immediate deletion:', error);
        throw new Error('internal: Failed to delete account');
    }
});

/**
 * Assigns a sweepfeed.app email address to a user when they upgrade to premium.
 */
exports.assignPremiumEmail = onDocumentUpdated(
    'users/{userId}',
    async (event) => {
        const userId = event.params.userId;
        const beforeData = event.data.before.data();
        const afterData = event.data.after.data();

        // Check if the user upgraded to premium
        if (beforeData.subscriptionTier !== 'premium' && afterData.subscriptionTier === 'premium') {
            // Check if the user already has a sweepfeed email
            if (afterData.sweepFeedEmail) {
                logger.info(`User ${userId} already has a sweepfeed email: ${afterData.sweepFeedEmail}`);
                return null;
            }

            // Generate a unique email address
            const shortId = userId.substring(0, 8);
            const email = `user${shortId}@sweepfeed.app`;

            // Save the email address to the user's document
            await db.collection('users').doc(userId).update({
                sweepFeedEmail: email
            });

            logger.info(`Assigned sweepfeed email ${email} to user ${userId}`);
            return null;
        }

        return null;
    }
);
