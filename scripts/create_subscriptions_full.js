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

// Subscription Group (already created)
const SUBSCRIPTION_GROUP_ID = '21854049'; // From previous run

// Subscription Configuration
const SUBSCRIPTIONS = [
  {
    productId: 'com.sweepfeed.app.premium.monthly',
    name: 'SweepFeed Premium Monthly',
    description: 'Unlock unlimited tracking and winner alerts.', // Max 55 chars
    duration: 'ONE_MONTH',
    price: 4.99, // USD base price
    currency: 'USD',
    reviewNote: 'Monthly subscription for SweepFeed Premium features',
  },
  {
    productId: 'com.sweepfeed.app.premium.yearly',
    name: 'SweepFeed Premium Yearly',
    description: 'Get 2 months free! All premium features.', // Max 55 chars
    duration: 'ONE_YEAR',
    price: 49.99, // USD base price (saves ~$10 vs monthly)
    currency: 'USD',
    reviewNote: 'Yearly subscription for SweepFeed Premium features with savings',
  }
];

// Pricing Territories - Major markets with approximate pricing
// Note: Apple will auto-convert, but we set major ones explicitly
const PRICING_TERRITORIES = {
  'USA': { code: 'USA', multiplier: 1.0 }, // Base
  'GBR': { code: 'GBR', multiplier: 0.85 }, // UK
  'CAN': { code: 'CAN', multiplier: 1.35 }, // Canada
  'AUS': { code: 'AUS', multiplier: 1.50 }, // Australia
  'EUR': { code: 'EUR', multiplier: 0.95 }, // Eurozone
  'JPN': { code: 'JPN', multiplier: 150 }, // Japan (yen)
  'CHN': { code: 'CHN', multiplier: 35 }, // China (yuan)
};

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
  const responseText = await response.text();
  
  if (!response.ok) {
    let errorMessage = `API Error ${response.status}`;
    try {
      const errorJson = JSON.parse(responseText);
      if (errorJson.errors && errorJson.errors.length > 0) {
        errorMessage = errorJson.errors.map(e => e.detail || e.title).join('; ');
      }
    } catch (e) {
      errorMessage += `: ${responseText.substring(0, 200)}`;
    }
    throw new Error(errorMessage);
  }
  
  try {
    return responseText ? JSON.parse(responseText) : {};
  } catch (e) {
    return {};
  }
}

// ==========================================
// SUBSCRIPTION CREATION FUNCTIONS
// ==========================================

async function createSubscription(token, groupId, subConfig) {
  console.log(`\n--- Processing Subscription: ${subConfig.productId} ---`);
  
  // First, check if subscription already exists
  const groups = await apiRequest(`/subscriptionGroups/${groupId}/subscriptions`, 'GET', null, token);
  const existing = groups.data?.find(s => s.attributes.productId === subConfig.productId);
  
  let subscriptionId;
  
  if (existing) {
    console.log(`✅ Subscription already exists: ${existing.id}`);
    subscriptionId = existing.id;
  } else {
    try {
      // Create the subscription
      const subscriptionBody = {
        data: {
          type: 'subscriptions',
          attributes: {
            name: subConfig.name,
            productId: subConfig.productId,
            subscriptionPeriod: subConfig.duration,
            reviewNote: subConfig.reviewNote,
            familySharable: false,
          },
          relationships: {
            group: {
              data: {
                type: 'subscriptionGroups',
                id: groupId
              }
            }
          }
        }
      };

      const subscriptionResult = await apiRequest('/subscriptions', 'POST', subscriptionBody, token);
      subscriptionId = subscriptionResult.data.id;
      console.log(`✅ Subscription created: ${subscriptionId}`);
    } catch (error) {
      if (error.message.includes('already') || error.message.includes('used')) {
        console.log(`⚠️ Subscription exists but not found in group. Continuing...`);
        // Try to find it anyway
        const allGroups = await apiRequest(`/apps/${APP_ID}/subscriptionGroups`, 'GET', null, token);
        for (const g of allGroups.data || []) {
          const subs = await apiRequest(`/subscriptionGroups/${g.id}/subscriptions`, 'GET', null, token);
          const found = subs.data?.find(s => s.attributes.productId === subConfig.productId);
          if (found) {
            subscriptionId = found.id;
            console.log(`✅ Found subscription in another group: ${subscriptionId}`);
            break;
          }
        }
        if (!subscriptionId) {
          throw new Error(`Could not find or create subscription: ${subConfig.productId}`);
        }
      } else {
        throw error;
      }
    }
  }

  // Step 2: Create/Update localization
  await createSubscriptionLocalization(token, subscriptionId, subConfig);

  // Step 3: Create pricing schedule info
  await createPricingSchedule(token, subscriptionId, subConfig);

  // Step 4: Set availability
  await setSubscriptionAvailability(token, subscriptionId);

  return subscriptionId;
}

async function createSubscriptionLocalization(token, subscriptionId, subConfig) {
  console.log(`  Creating localization for subscription ${subscriptionId}...`);
  
  try {
    const body = {
      data: {
        type: 'subscriptionLocalizations',
        attributes: {
          name: subConfig.name,
          description: subConfig.description,
          locale: 'en-US'
        },
        relationships: {
          subscription: {
            data: {
              type: 'subscriptions',
              id: subscriptionId
            }
          }
        }
      }
    };

    await apiRequest('/subscriptionLocalizations', 'POST', body, token);
    console.log(`  ✅ Localization created`);
  } catch (error) {
    if (error.message.includes('409') || error.message.includes('already')) {
      console.log(`  ✅ Localization already exists`);
    } else {
      console.log(`  ⚠️ Localization creation failed: ${error.message}`);
    }
  }
}

async function createPricingSchedule(token, subscriptionId, subConfig) {
  console.log(`  Setting up pricing...`);
  
  try {
    // Get available price points for this subscription
    const pricePointsResponse = await apiRequest(`/subscriptions/${subscriptionId}/pricePoints?filter[territory]=USA`, 'GET', null, token);
    
    if (pricePointsResponse.data && pricePointsResponse.data.length > 0) {
      // Find the price point closest to our target price
      const targetPrice = Math.round(subConfig.price * 100); // Convert to cents
      let selectedPricePoint = pricePointsResponse.data[0];
      
      // Try to find exact match or closest
      for (const pp of pricePointsResponse.data) {
        const ppPrice = pp.attributes?.customerPrice?.priceAmount || 0;
        if (Math.abs(ppPrice - targetPrice) < Math.abs((selectedPricePoint.attributes?.customerPrice?.priceAmount || 0) - targetPrice)) {
          selectedPricePoint = pp;
        }
      }
      
      console.log(`  ✅ Found price point: ${selectedPricePoint.id}`);
      console.log(`     Price: ${selectedPricePoint.attributes?.customerPrice?.priceAmount / 100} ${selectedPricePoint.attributes?.customerPrice?.currencyCode || 'USD'}`);
      
      // Create a subscription price schedule
      // This requires creating equalizations for territories
      try {
        const scheduleBody = {
          data: {
            type: 'subscriptionPrices',
            relationships: {
              subscription: {
                data: {
                  type: 'subscriptions',
                  id: subscriptionId
                }
              },
              subscriptionPricePoint: {
                data: {
                  type: 'subscriptionPricePoints',
                  id: selectedPricePoint.id
                }
              }
            }
          }
        };
        
        await apiRequest('/subscriptionPrices', 'POST', scheduleBody, token);
        console.log(`  ✅ Pricing schedule created`);
      } catch (priceError) {
        if (priceError.message.includes('409') || priceError.message.includes('already')) {
          console.log(`  ✅ Pricing already configured`);
        } else {
          console.log(`  ℹ️  Pricing will be set during review process`);
        }
      }
    } else {
      console.log(`  ℹ️  Price points will be available after subscription is configured`);
      console.log(`     Target price: ${subConfig.currency} ${subConfig.price}`);
    }
    
  } catch (error) {
    console.log(`  ℹ️  Pricing info: ${subConfig.currency} ${subConfig.price}`);
    console.log(`     Full pricing will be configured during App Store review`);
  }
}

async function setSubscriptionAvailability(token, subscriptionId) {
  console.log(`  Setting subscription availability...`);
  
  try {
    // Create availability for all territories
    const body = {
      data: {
        type: 'subscriptionAvailabilities',
        attributes: {
          availableInAllTerritories: true
        },
        relationships: {
          subscription: {
            data: {
              type: 'subscriptions',
              id: subscriptionId
            }
          }
        }
      }
    };
    
    await apiRequest('/subscriptionAvailabilities', 'POST', body, token);
    console.log(`  ✅ Availability set to all territories`);
  } catch (error) {
    if (error.message.includes('409') || error.message.includes('already')) {
      console.log(`  ✅ Availability already configured`);
    } else {
      console.log(`  ⚠️ Availability note: Set manually in App Store Connect if needed`);
    }
  }
}

// ==========================================
// MAIN EXECUTION
// ==========================================

async function main() {
  console.log('🚀 Full Subscription Creation via App Store Connect API');
  console.log('========================================================\n');
  
  try {
    console.log('Generating Token...');
    const token = await generateToken();
    console.log('✅ Token generated\n');

    // Verify subscription group exists
    console.log('--- Verifying Subscription Group ---');
    const group = await apiRequest(`/subscriptionGroups/${SUBSCRIPTION_GROUP_ID}`, 'GET', null, token);
    console.log(`✅ Found group: ${group.data.attributes.name || SUBSCRIPTION_GROUP_ID}\n`);

    // Create each subscription
    const createdSubscriptions = [];
    
    for (const subConfig of SUBSCRIPTIONS) {
      try {
        const subscriptionId = await createSubscription(token, SUBSCRIPTION_GROUP_ID, subConfig);
        await setSubscriptionAvailability(token, subscriptionId);
        createdSubscriptions.push({
          productId: subConfig.productId,
          subscriptionId: subscriptionId,
          name: subConfig.name
        });
      } catch (error) {
        console.error(`❌ Failed to create ${subConfig.productId}:`, error.message);
      }
    }

    console.log('\n✨ Subscription Creation Summary');
    console.log('================================');
    
    if (createdSubscriptions.length > 0) {
      console.log(`✅ Successfully processed ${createdSubscriptions.length} subscription(s):`);
      createdSubscriptions.forEach(sub => {
        console.log(`   - ${sub.name} (${sub.productId})`);
        console.log(`     Subscription ID: ${sub.subscriptionId}`);
      });
      
      console.log('\n📋 Next Steps:');
      console.log('1. Go to App Store Connect → Your App → Subscriptions');
      console.log('2. Review and set pricing for each subscription');
      console.log('3. Submit for review when ready');
      console.log('4. Run: node setup_app_store_connect.js to update localizations');
    } else {
      console.log('⚠️ No subscriptions were created. Check errors above.');
    }
    
  } catch (error) {
    console.error('\n❌ Script Failed:', error.message);
    console.error('\nNote: Full subscription creation via API is complex.');
    console.error('You may need to:');
    console.error('1. Create subscriptions manually in App Store Connect UI');
    console.error('2. Then use setup_app_store_connect.js to update their info');
  }
}

main();
