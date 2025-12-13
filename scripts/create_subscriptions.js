const { readFileSync } = require('fs');
const jwt = require('jsonwebtoken');
const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));

// ==========================================
// CONFIGURATION
// ==========================================

const KEY_ID = 'M8KG7LHWQ4';
const ISSUER_ID = '2179fed4-8cf8-485b-94f1-de7fd2fdd6ac';
const PRIVATE_KEY_PATH = __dirname + '/AuthKey_M8KG7LHWQ4.p8';
const APP_ID = '6744655863';

// Subscription Configuration
const SUBSCRIPTION_GROUP_NAME = 'SweepFeed Premium';
const SUBSCRIPTIONS = [
  {
    productId: 'com.sweepfeed.app.premium.monthly',
    name: 'SweepFeed Premium Monthly',
    description: 'Unlock unlimited tracking, winner alerts, and premium features.',
    duration: 'P1M', // 1 month
    price: 4.99, // USD
    currency: 'USD'
  },
  {
    productId: 'com.sweepfeed.app.premium.yearly',
    name: 'SweepFeed Premium Yearly',
    description: 'Get 2 months free! Unlock all premium features for a full year.',
    duration: 'P1Y', // 1 year
    price: 49.99, // USD
    currency: 'USD'
  }
];

// ==========================================
// HELPER FUNCTIONS
// ==========================================

async function generateToken() {
  try {
    const privateKey = readFileSync(PRIVATE_KEY_PATH, 'utf8');
    const now = Math.floor(Date.now() / 1000);
    return jwt.sign({
      iss: ISSUER_ID,
      iat: now,
      exp: now + 1200,
      aud: 'appstoreconnect-v1'
    }, privateKey, {
      algorithm: 'ES256',
      header: { alg: 'ES256', kid: KEY_ID, typ: 'JWT' },
    });
  } catch (e) {
    console.error(`Error reading private key:`, e.message);
    process.exit(1);
  }
}

async function apiRequest(endpoint, method = 'GET', body = null, token) {
  const url = `https://api.appstoreconnect.apple.com/v1${endpoint}`;
  const options = {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  };
  if (body) options.body = JSON.stringify(body);

  const response = await fetch(url, options);
  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`API Error ${response.status} ${url}: ${errorText}`);
  }
  return response.json();
}

// ==========================================
// MAIN FUNCTIONS
// ==========================================

async function createOrGetSubscriptionGroup(token) {
  console.log('\n--- Setting up Subscription Group ---');
  
  // Check if group exists
  const groups = await apiRequest(`/apps/${APP_ID}/subscriptionGroups`, 'GET', null, token);
  
  let group = groups.data?.find(g => g.attributes.name === SUBSCRIPTION_GROUP_NAME);
  
  if (group) {
    console.log(`✅ Subscription group "${SUBSCRIPTION_GROUP_NAME}" already exists`);
    return group.id;
  }

  // Create new group
  console.log(`Creating subscription group: "${SUBSCRIPTION_GROUP_NAME}"`);
  const body = {
    data: {
      type: 'subscriptionGroups',
      attributes: {
        referenceName: SUBSCRIPTION_GROUP_NAME
      },
      relationships: {
        app: {
          data: {
            type: 'apps',
            id: APP_ID
          }
        }
      }
    }
  };

  const result = await apiRequest('/subscriptionGroups', 'POST', body, token);
  console.log(`✅ Created subscription group: ${result.data.id}`);
  return result.data.id;
}

async function createSubscription(token, groupId, subConfig) {
  console.log(`\n--- Creating Subscription: ${subConfig.productId} ---`);
  
  // Check if subscription already exists in the group
  const existingSubs = await apiRequest(`/subscriptionGroups/${groupId}/subscriptions`, 'GET', null, token);
  const existing = existingSubs.data?.find(s => s.attributes.productId === subConfig.productId);
  
  if (existing) {
    console.log(`⚠️ Subscription ${subConfig.productId} already exists. Skipping creation.`);
    return existing.id;
  }

  // Note: Creating subscriptions via API requires pricing territories and is complex
  // For now, we'll provide instructions
  console.log(`\n📝 To create subscription "${subConfig.productId}":`);
  console.log(`   1. Go to App Store Connect > Your App > Subscriptions`);
  console.log(`   2. Select the "${SUBSCRIPTION_GROUP_NAME}" group`);
  console.log(`   3. Click "+" to add a new subscription`);
  console.log(`   4. Use Product ID: ${subConfig.productId}`);
  console.log(`   5. Set pricing and duration`);
  console.log(`   6. Then run the main script to update localizations`);
  
  // The API requires pricing schedules which are complex to set up
  // It's easier to create via UI, then update localizations via API
  return null;
}

async function main() {
  try {
    console.log('Generating Token...');
    const token = await generateToken();

    const groupId = await createOrGetSubscriptionGroup(token);
    
    console.log('\n📋 Next Steps:');
    console.log('1. Go to App Store Connect > Your App > Subscriptions');
    console.log('2. Create subscriptions manually in the UI with these Product IDs:');
    SUBSCRIPTIONS.forEach(sub => {
      console.log(`   - ${sub.productId} (${sub.name})`);
    });
    console.log('3. After creating subscriptions, run: node setup_app_store_connect.js');
    console.log('   This will update the subscription names and descriptions automatically.');
    
  } catch (error) {
    console.error('\n❌ Script Failed:', error.message);
  }
}

main();
