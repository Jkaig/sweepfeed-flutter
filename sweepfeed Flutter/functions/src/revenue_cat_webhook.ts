import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';

interface RevenueCatEvent {
  customer_id: string;
  app_user_id: string;
  type: string;
  product: {
    identifier: string;
    price: number;
    currency: string;
  };
  entitlements: {
    [key: string]: {
      expires_date: string;
      product_identifier: string;
    };
  };
}

function verifyRevenueCatWebhook(
  req: functions.https.Request,
  secret: string
): boolean {
  const signature = req.headers['revenuecat-signature'] as string;
  if (!signature) {
    console.error('Missing RevenueCat signature header');
    return false;
  }

  const body = JSON.stringify(req.body);
  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(body)
    .digest('hex');

  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expectedSignature)
  );
}

function getTierFromProductId(productId: string): string {
  if (productId.includes('premium') || productId.includes('premium_annual')) {
    return 'premium';
  } else if (productId.includes('basic') || productId.includes('basic_annual')) {
    return 'basic';
  }
  return 'free';
}

export const revenueCatWebhook = functions.https.onRequest(
  async (req, res) => {
    try {
      const secret = functions.config().revenuecat?.webhook_secret;
      if (!secret) {
        console.error('RevenueCat webhook secret not configured');
        return res.status(500).send('Server configuration error');
      }

      if (!verifyRevenueCatWebhook(req, secret)) {
        console.error('Webhook signature verification failed');
        return res.status(401).send('Unauthorized');
      }

      const event: RevenueCatEvent = req.body;
      const userId = event.app_user_id;
      const eventType = event.type;

      console.log(`RevenueCat webhook: ${eventType} for user ${userId}`);

      const db = admin.firestore();
      const userRef = db.collection('users').doc(userId);

      switch (eventType) {
        case 'INITIAL_PURCHASE':
        case 'RENEWAL':
        case 'NON_RENEWING_PURCHASE': {
          const tier = getTierFromProductId(event.product.identifier);
          
          await db.runTransaction(async (transaction) => {
            const userDoc = await transaction.get(userRef);
            
            if (!userDoc.exists) {
              throw new Error(`User ${userId} not found`);
            }

            const updates: any = {
              subscriptionTier: tier,
              tierUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
              lastPurchaseDate: admin.firestore.FieldValue.serverTimestamp(),
            };

            if (event.entitlements) {
              const entitlementKeys = Object.keys(event.entitlements);
              if (entitlementKeys.length > 0) {
                const entitlement = event.entitlements[entitlementKeys[0]];
                if (entitlement.expires_date) {
                  updates.subscriptionExpiresAt = new Date(
                    entitlement.expires_date
                  );
                }
              }
            }

            transaction.update(userRef, updates);

            await db
              .collection('users')
              .doc(userId)
              .collection('server_side_confirmation')
              .doc('subscription')
              .set(
                {
                  confirmed: true,
                  tier,
                  timestamp: admin.firestore.FieldValue.serverTimestamp(),
                  source: 'revenuecat_webhook',
                  event_type: eventType,
                },
                { merge: true }
              );
          });

          await db.collection('subscription_analytics').add({
            userId,
            event: 'subscription_purchase',
            tier,
            productId: event.product.identifier,
            price: event.product.price,
            currency: event.product.currency,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            source: 'webhook',
          });

          console.log(`Updated tier to ${tier} for user ${userId}`);
          break;
        }

        case 'CANCELLATION':
        case 'EXPIRATION': {
          await db.runTransaction(async (transaction) => {
            const userDoc = await transaction.get(userRef);
            
            if (!userDoc.exists) {
              throw new Error(`User ${userId} not found`);
            }

            transaction.update(userRef, {
              subscriptionTier: 'free',
              tierUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
              subscriptionCancelledAt:
                admin.firestore.FieldValue.serverTimestamp(),
            });

            await db
              .collection('users')
              .doc(userId)
              .collection('server_side_confirmation')
              .doc('subscription')
              .set(
                {
                  confirmed: true,
                  tier: 'free',
                  timestamp: admin.firestore.FieldValue.serverTimestamp(),
                  source: 'revenuecat_webhook',
                  event_type: eventType,
                },
                { merge: true }
              );
          });

          await db.collection('subscription_analytics').add({
            userId,
            event: eventType.toLowerCase(),
            tier: 'free',
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            source: 'webhook',
          });

          console.log(`Downgraded to free tier for user ${userId}`);
          break;
        }

        case 'BILLING_ISSUE': {
          await userRef.update({
            subscriptionStatus: 'billing_issue',
            lastBillingIssueAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          console.log(`Billing issue reported for user ${userId}`);
          break;
        }

        default:
          console.log(`Unhandled webhook event type: ${eventType}`);
      }

      await db.collection('webhook_logs').add({
        source: 'revenuecat',
        event_type: eventType,
        user_id: userId,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        payload: event,
      });

      res.status(200).send('OK');
    } catch (error) {
      console.error('Error processing RevenueCat webhook:', error);
      
      await admin.firestore().collection('webhook_errors').add({
        source: 'revenuecat',
        error: error instanceof Error ? error.message : 'Unknown error',
        stack: error instanceof Error ? error.stack : null,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        payload: req.body,
      });

      res.status(500).send('Internal Server Error');
    }
  }
);

export const validateSubscription = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const userId = context.auth.uid;

    try {
      const db = admin.firestore();
      const userDoc = await db.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'User not found');
      }

      const userData = userDoc.data();
      const tier = userData?.subscriptionTier || 'free';
      const expiresAt = userData?.subscriptionExpiresAt?.toDate();

      const isActive =
        tier !== 'free' &&
        (!expiresAt || expiresAt.getTime() > Date.now());

      return {
        tier,
        isActive,
        expiresAt: expiresAt?.toISOString(),
      };
    } catch (error) {
      console.error('Error validating subscription:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to validate subscription'
      );
    }
  }
);
