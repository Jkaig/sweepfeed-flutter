const { readFileSync } = require('fs');
const jwt = require('jsonwebtoken');
const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));

// ==========================================
// CONFIGURATION
// ==========================================

// API Credentials
const KEY_ID = 'M8KG7LHWQ4'; // Extracted from AuthKey_M8KG7LHWQ4.p8
const ISSUER_ID = '2179fed4-8cf8-485b-94f1-de7fd2fdd6ac'; // Issuer ID from App Store Connect
const PRIVATE_KEY_PATH = __dirname + '/AuthKey_M8KG7LHWQ4.p8'; // Key copied from Downloads
const APP_ID = '6756335183'; // SweepFeed App Apple ID (updated after recreation)

// Basic App Info (App Info Localizations)
const APP_INFO = {
  locale: 'en-US',
  name: 'SweepFeed',
  subtitle: 'Your Daily Shot at Glory', // Max 30 chars
  privacyPolicyUrl: 'https://sweepfeed.app/privacy',
  privacyPolicyText: 'We respect your privacy...' // Optional, usually for tvOS
};

// App Category Configuration
const APP_CATEGORY = {
  primaryCategory: 'ENTERTAINMENT', // Primary category
  secondaryCategory: 'LIFESTYLE' // Optional secondary category
};

// Version Info (App Store Version Localizations)
const VERSION_INFO = {
  locale: 'en-US',
  description: `SweepFeed helps you discover and track the best sweepstakes and contests.
  
Features:
- Organized Feed
- Track Entries
- Winner Notifications`,
  keywords: 'sweepstakes, contests, win, prizes, tracker, giveaways',
  marketingUrl: 'https://sweepfeed.app',
  supportUrl: 'https://sweepfeed.app/support',
  promotionalText: 'Download now and start winning!'
};

// Subscription Info (Optional - Add your product IDs)
// This updates the localization (Name/Description) for existing subscriptions
const SUBSCRIPTIONS = [
  {
    productId: 'com.sweepfeed.app.premium.monthly',
    locale: 'en-US',
    name: 'SweepFeed Premium',
    description: 'Ad-free! Unlimited tracking & winner alerts.'
  },
  {
    productId: 'com.sweepfeed.app.premium.yearly',
    locale: 'en-US',
    name: 'SweepFeed Premium (Yearly)',
    description: 'Ad-free! Get 2 months free & all features.'
  }
];

// ==========================================
// HELPER FUNCTIONS
// ==========================================

async function generateToken() {
  try {
    const privateKey = readFileSync(PRIVATE_KEY_PATH, 'utf8');
    const now = Math.floor(Date.now() / 1000);
    const token = jwt.sign({
      iss: ISSUER_ID,
      iat: now,
      exp: now + 1200, // 20 minutes
      aud: 'appstoreconnect-v1'
    }, privateKey, {
      algorithm: 'ES256',
      header: { 
        alg: 'ES256', 
        kid: KEY_ID, 
        typ: 'JWT' 
      },
    });
    console.log('Token generated successfully');
    return token;
  } catch (e) {
    console.error(`Error reading private key from ${PRIVATE_KEY_PATH}:`, e.message);
    console.error('Full error:', e);
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
// MAIN TASKS
// ==========================================

async function updateAppCategories(token) {
  console.log('\n--- Setting App Categories ---');
  console.log('ℹ️  Note: Categories must be set manually in App Store Connect UI');
  console.log('   Go to: App Store Connect > Your App > App Information');
  console.log('   Set Primary Category: Entertainment');
  console.log('   Set Secondary Category (optional): Lifestyle');
  console.log('   This is a limitation of the App Store Connect API for new apps.');
}

async function updateBasicAppInfo(token) {
  console.log('\n--- Updating Basic App Info ---');
  try {
    // 1. Get App Info ID
    const appInfos = await apiRequest(`/apps/${APP_ID}/appInfos`, 'GET', null, token);
    if (!appInfos.data || appInfos.data.length === 0) {
      console.log('⚠️ No app info found. Creating app info localization...');
      // Try to create if app exists but no info
      return;
    }
    const appInfoId = appInfos.data[0].id;

    // 2. Get Localizations
    const localizations = await apiRequest(`/appInfos/${appInfoId}/appInfoLocalizations`, 'GET', null, token);
    let targetLoc = localizations.data?.find(l => l.attributes.locale === APP_INFO.locale);

    if (!targetLoc) {
      console.log(`Localization ${APP_INFO.locale} not found. Creating new...`);
      // Create new localization
      const createBody = {
        data: {
          type: 'appInfoLocalizations',
          attributes: {
            locale: APP_INFO.locale,
            name: APP_INFO.name,
            subtitle: APP_INFO.subtitle,
            privacyPolicyUrl: APP_INFO.privacyPolicyUrl,
          },
          relationships: {
            appInfo: {
              data: {
                type: 'appInfos',
                id: appInfoId
              }
            }
          }
        }
      };
      const created = await apiRequest('/appInfoLocalizations', 'POST', createBody, token);
      targetLoc = created.data;
      console.log('✅ Created new app info localization');
    } else {
      // 3. Update existing
      const body = {
        data: {
          id: targetLoc.id,
          type: 'appInfoLocalizations',
          attributes: {
            name: APP_INFO.name,
            subtitle: APP_INFO.subtitle,
            privacyPolicyUrl: APP_INFO.privacyPolicyUrl,
          }
        }
      };

      await apiRequest(`/appInfoLocalizations/${targetLoc.id}`, 'PATCH', body, token);
      console.log('✅ Basic App Info updated.');
    }
  } catch (error) {
    console.log('⚠️ App Info update error:', error.message);
    if (error.message.includes('404')) {
      console.log('   App may need initial setup in App Store Connect UI first');
    }
  }
}


async function updateSubscriptionInfo(token) {
  console.log('\n--- Updating Subscription Info ---');
  
  try {
    // 1. Get all subscription groups
    const groups = await apiRequest(`/apps/${APP_ID}/subscriptionGroups`, 'GET', null, token);
    
    if (!groups.data || groups.data.length === 0) {
      console.log('⚠️ No subscription groups found.');
      console.log('   To set up subscriptions:');
      console.log('   1. Go to App Store Connect > Your App > Subscriptions');
      console.log('   2. Create a Subscription Group');
      console.log('   3. Add subscription products');
      console.log('   4. Run this script again to update their info');
      return;
    }

    console.log(`Found ${groups.data.length} subscription group(s)`);

    // 2. Process all groups and their subscriptions
    for (const group of groups.data) {
      console.log(`\nProcessing subscription group: ${group.attributes.name || group.id}`);
      
      const allSubs = await apiRequest(`/subscriptionGroups/${group.id}/subscriptions`, 'GET', null, token);
      
      if (!allSubs.data || allSubs.data.length === 0) {
        console.log('  No subscriptions in this group');
        continue;
      }

      console.log(`  Found ${allSubs.data.length} subscription(s)`);

      // 3. Update each subscription
      for (const remoteSub of allSubs.data) {
        const productId = remoteSub.attributes.productId;
        console.log(`  Processing: ${productId}`);

        // Find matching config or use defaults
        const subConfig = SUBSCRIPTIONS.find(s => s.productId === productId) || {
          productId: productId,
          locale: 'en-US',
          name: 'SweepFeed Premium',
          description: 'Unlock premium features and unlimited tracking.'
        };

        // Get existing localizations
        const locs = await apiRequest(`/subscriptions/${remoteSub.id}/subscriptionLocalizations`, 'GET', null, token);
        const targetLoc = locs.data.find(l => l.attributes.locale === subConfig.locale);

        if (targetLoc) {
          // Update existing localization
          const body = {
            data: {
              id: targetLoc.id,
              type: 'subscriptionLocalizations',
              attributes: {
                name: subConfig.name,
                description: subConfig.description
              }
            }
          };
          await apiRequest(`/subscriptionLocalizations/${targetLoc.id}`, 'PATCH', body, token);
          console.log(`    ✅ Updated localization for: ${productId}`);
        } else {
          // Create new localization
          const body = {
            data: {
              type: "subscriptionLocalizations",
              attributes: {
                name: subConfig.name,
                description: subConfig.description,
                locale: subConfig.locale
              },
              relationships: {
                subscription: {
                  data: {
                    type: "subscriptions",
                    id: remoteSub.id
                  }
                }
              }
            }
          };
          await apiRequest(`/subscriptionLocalizations`, 'POST', body, token);
          console.log(`    ✅ Created localization for: ${productId}`);
        }
      }
    }
    
    console.log('\n✅ Subscription info update completed!');
  } catch (error) {
    console.log('⚠️ Subscription update error:', error.message);
    if (error.message.includes('404') || error.message.includes('PATH_ERROR')) {
      console.log('   (Subscriptions may not be set up yet in App Store Connect)');
    }
  }
}

// ==========================================
// RUN
// ==========================================

async function createOrUpdateVersionLocalization(token) {
  console.log('\n--- Creating/Updating Version Localization ---');
  try {
    // 1. Get or create app store version
    let versions = await apiRequest(`/apps/${APP_ID}/appStoreVersions?filter[appStoreState]=PREPARE_FOR_SUBMISSION`, 'GET', null, token);
    
    let versionId;
    if (!versions.data || versions.data.length === 0) {
      // Try to get any version
      versions = await apiRequest(`/apps/${APP_ID}/appStoreVersions`, 'GET', null, token);
      if (versions.data && versions.data.length > 0) {
        versionId = versions.data[0].id;
        console.log(`Using existing version: ${versionId}`);
      } else {
        console.log('⚠️ No app store version found. You may need to create one in App Store Connect first.');
        return;
      }
    } else {
      versionId = versions.data[0].id;
    }

    // 2. Get Localizations
    const localizations = await apiRequest(`/appStoreVersions/${versionId}/appStoreVersionLocalizations`, 'GET', null, token);
    let targetLoc = localizations.data?.find(l => l.attributes.locale === VERSION_INFO.locale);

    if (!targetLoc) {
      console.log(`Version Localization ${VERSION_INFO.locale} not found. Creating new...`);
      // Create new localization
      const createBody = {
        data: {
          type: 'appStoreVersionLocalizations',
          attributes: {
            locale: VERSION_INFO.locale,
            description: VERSION_INFO.description,
            keywords: VERSION_INFO.keywords,
            marketingUrl: VERSION_INFO.marketingUrl,
            supportUrl: VERSION_INFO.supportUrl,
            promotionalText: VERSION_INFO.promotionalText
          },
          relationships: {
            appStoreVersion: {
              data: {
                type: 'appStoreVersions',
                id: versionId
              }
            }
          }
        }
      };
      await apiRequest('/appStoreVersionLocalizations', 'POST', createBody, token);
      console.log('✅ Created new version localization');
    } else {
      // Update existing
      const body = {
        data: {
          id: targetLoc.id,
          type: 'appStoreVersionLocalizations',
          attributes: {
            description: VERSION_INFO.description,
            keywords: VERSION_INFO.keywords,
            marketingUrl: VERSION_INFO.marketingUrl,
            supportUrl: VERSION_INFO.supportUrl,
            promotionalText: VERSION_INFO.promotionalText
          }
        }
      };

      await apiRequest(`/appStoreVersionLocalizations/${targetLoc.id}`, 'PATCH', body, token);
      console.log('✅ Version Info updated.');
    }
  } catch (error) {
    console.log('⚠️ Version localization error:', error.message);
  }
}

async function main() {
  try {
    console.log('🚀 Starting App Store Connect Setup...');
    console.log(`App ID: ${APP_ID}`);
    console.log(`Bundle ID: com.sweepfeed.app`);
    console.log('Generating Token...');
    const token = await generateToken();

    // Order matters - set up basic structure first
    await updateAppCategories(token);
    await updateBasicAppInfo(token);
    await createOrUpdateVersionLocalization(token);
    await updateSubscriptionInfo(token);

    console.log('\n✨ All operations completed successfully!');
    console.log('\n📝 Summary of Updates:');
    console.log('✅ App Name: SweepFeed');
    console.log('✅ Subtitle: Your Daily Shot at Glory');
    console.log('✅ Privacy Policy URL: https://sweepfeed.app/privacy');
    console.log('✅ App Store Version Description updated');
    console.log('✅ Keywords, Marketing URL, Support URL updated');
    console.log('\n📋 Manual Steps Required in App Store Connect:');
    console.log('1. Set Categories:');
    console.log('   - Primary: Entertainment');
    console.log('   - Secondary: Lifestyle (optional)');
    console.log('   Location: App Information > Category');
    console.log('');
    console.log('2. Upload App Icon:');
    console.log('   - Location: App Information > App Icon');
    console.log('   - Use: assets/icon/ios_app_icon_1024.png (1024x1024px)');
    console.log('');
    console.log('3. Set Age Ratings:');
    console.log('   - Location: App Information > Age Ratings');
    console.log('   - Answer the questionnaire based on your app content');
    console.log('');
    console.log('4. Upload Screenshots:');
    console.log('   - Location: App Store > 1.0 Prepare for Submission');
    console.log('   - Required sizes: iPhone 6.7", 6.5", 5.5" displays');
    console.log('');
    console.log('5. Complete App Privacy (if not done):');
    console.log('   - Location: App Privacy');
    console.log('   - Declare data collection practices');
  } catch (error) {
    console.error('\n❌ Script Failed:', error.message);
    console.error('Full error:', error);
  }
}

main();
