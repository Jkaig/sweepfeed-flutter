const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));

// ==========================================
// CONFIGURATION
// ==========================================

// RevenueCat API Configuration
// Get your Secret API Key from: RevenueCat Dashboard → Settings → API Keys → Secret Keys
const REVENUECAT_SECRET_API_KEY = 'YOUR_SECRET_API_KEY_HERE';

// Get your Project ID from RevenueCat Dashboard URL or API
// It's usually in the format: app_xxxxxxxxxxxxx
const REVENUECAT_PROJECT_ID = 'YOUR_PROJECT_ID_HERE';

// Subscription Configuration
// These should match your App Store Connect subscription product IDs
const SUBSCRIPTIONS = {
  monthly: {
    identifier: 'monthly',
    iosStoreProductId: 'com.sweepfeed.app.premium.monthly',
    androidStoreProductId: 'com.sweepfeed.app.premium.monthly', // Same for now, can be different
  },
  yearly: {
    identifier: 'yearly',
    iosStoreProductId: 'com.sweepfeed.app.premium.yearly',
    androidStoreProductId: 'com.sweepfeed.app.premium.yearly',
  }
};

const ENTITLEMENT_ID = 'SweepFeed Pro';
const ENTITLEMENT_DISPLAY_NAME = 'SweepFeed Pro';
const OFFERING_ID = 'default';
const OFFERING_DISPLAY_NAME = 'Default Offering';

// ==========================================
// HELPER FUNCTIONS
// ==========================================

function getHeaders() {
  if (!REVENUECAT_SECRET_API_KEY || REVENUECAT_SECRET_API_KEY === 'YOUR_SECRET_API_KEY_HERE') {
    throw new Error('REVENUECAT_SECRET_API_KEY not configured. Get it from RevenueCat Dashboard → Settings → API Keys');
  }
  
  return {
    'Authorization': `Bearer ${REVENUECAT_SECRET_API_KEY}`,
    'Content-Type': 'application/json',
    'X-Platform': 'nodejs',
  };
}

async function apiRequest(endpoint, method = 'GET', body = null) {
  const url = `https://api.revenuecat.com/v1/projects/${REVENUECAT_PROJECT_ID}${endpoint}`;
  const options = {
    method,
    headers: getHeaders(),
  };
  if (body) options.body = JSON.stringify(body);

  const response = await fetch(url, options);
  const responseText = await response.text();
  
  if (!response.ok) {
    let errorMessage = `API Error ${response.status}: ${responseText}`;
    try {
      const errorJson = JSON.parse(responseText);
      if (errorJson.message) errorMessage = errorJson.message;
      if (errorJson.errors) errorMessage = JSON.stringify(errorJson.errors);
    } catch (e) {
      // Keep original error message
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
// MAIN SETUP FUNCTIONS
// ==========================================

async function createEntitlement() {
  console.log('\n--- Creating Entitlement ---');
  try {
    const body = {
      identifier: ENTITLEMENT_ID,
      display_name: ENTITLEMENT_DISPLAY_NAME,
    };
    
    await apiRequest('/entitlements', 'POST', body);
    console.log(`✅ Entitlement "${ENTITLEMENT_ID}" created/updated`);
    return true;
  } catch (error) {
    if (error.message.includes('409') || error.message.includes('already exists')) {
      console.log(`✅ Entitlement "${ENTITLEMENT_ID}" already exists`);
      return true;
    }
    console.error(`❌ Failed to create entitlement:`, error.message);
    return false;
  }
}

async function createProduct(identifier, storeProductId, platform) {
  console.log(`\n--- Creating Product: ${identifier} (${platform}) ---`);
  try {
    const body = {
      identifier: identifier,
      store_product_id: storeProductId,
      platform: platform,
    };
    
    await apiRequest('/products', 'POST', body);
    console.log(`✅ Product "${identifier}" created for ${platform}`);
    return true;
  } catch (error) {
    if (error.message.includes('409') || error.message.includes('already exists')) {
      console.log(`✅ Product "${identifier}" already exists for ${platform}`);
      return true;
    }
    console.error(`❌ Failed to create product:`, error.message);
    return false;
  }
}

async function attachProductToEntitlement(productIdentifier, platform) {
  console.log(`\n--- Attaching Product to Entitlement ---`);
  try {
    const body = {
      product_identifier: productIdentifier,
      platform: platform,
    };
    
    await apiRequest(`/entitlements/${ENTITLEMENT_ID}/products`, 'POST', body);
    console.log(`✅ Product "${productIdentifier}" attached to "${ENTITLEMENT_ID}" (${platform})`);
    return true;
  } catch (error) {
    if (error.message.includes('409') || error.message.includes('already')) {
      console.log(`✅ Product already attached`);
      return true;
    }
    console.error(`❌ Failed to attach product:`, error.message);
    return false;
  }
}

async function createOffering() {
  console.log('\n--- Creating Offering ---');
  try {
    const body = {
      identifier: OFFERING_ID,
      display_name: OFFERING_DISPLAY_NAME,
    };
    
    await apiRequest('/offerings', 'POST', body);
    console.log(`✅ Offering "${OFFERING_ID}" created`);
    return true;
  } catch (error) {
    if (error.message.includes('409') || error.message.includes('already exists')) {
      console.log(`✅ Offering "${OFFERING_ID}" already exists`);
      return true;
    }
    console.error(`❌ Failed to create offering:`, error.message);
    return false;
  }
}

async function addPackageToOffering(packageIdentifier, productIdentifier, platform) {
  console.log(`\n--- Adding Package to Offering ---`);
  try {
    const body = {
      identifier: packageIdentifier,
      product_identifier: productIdentifier,
      platform: platform,
    };
    
    await apiRequest(`/offerings/${OFFERING_ID}/packages`, 'POST', body);
    console.log(`✅ Package "${packageIdentifier}" added to offering (${platform})`);
    return true;
  } catch (error) {
    if (error.message.includes('409') || error.message.includes('already')) {
      console.log(`✅ Package already in offering`);
      return true;
    }
    console.error(`❌ Failed to add package:`, error.message);
    return false;
  }
}

async function setDefaultOffering() {
  console.log('\n--- Setting Default Offering ---');
  try {
    const body = {
      is_default: true,
    };
    
    await apiRequest(`/offerings/${OFFERING_ID}`, 'PATCH', body);
    console.log(`✅ Offering "${OFFERING_ID}" set as default`);
    return true;
  } catch (error) {
    console.error(`❌ Failed to set default offering:`, error.message);
    return false;
  }
}

// ==========================================
// MAIN SETUP FLOW
// ==========================================

async function setupRevenueCat() {
  console.log('🚀 RevenueCat Setup Script');
  console.log('==========================\n');
  
  // Validate configuration
  if (!REVENUECAT_SECRET_API_KEY || REVENUECAT_SECRET_API_KEY === 'YOUR_SECRET_API_KEY_HERE') {
    console.error('❌ REVENUECAT_SECRET_API_KEY not configured!');
    console.log('\nTo get your Secret API Key:');
    console.log('1. Go to https://app.revenuecat.com');
    console.log('2. Navigate to Settings → API Keys → Secret Keys');
    console.log('3. Copy your secret key');
    console.log('4. Update REVENUECAT_SECRET_API_KEY in this script\n');
    process.exit(1);
  }
  
  if (!REVENUECAT_PROJECT_ID || REVENUECAT_PROJECT_ID === 'YOUR_PROJECT_ID_HERE') {
    console.error('❌ REVENUECAT_PROJECT_ID not configured!');
    console.log('\nTo get your Project ID:');
    console.log('1. Go to RevenueCat Dashboard');
    console.log('2. Check the URL - it contains your project ID');
    console.log('3. Or go to Settings → Project Settings');
    console.log('4. Update REVENUECAT_PROJECT_ID in this script\n');
    process.exit(1);
  }

  try {
    // 1. Create Entitlement
    await createEntitlement();

    // 2. Create Products for iOS
    const monthlyIOSCreated = await createProduct(
      SUBSCRIPTIONS.monthly.identifier,
      SUBSCRIPTIONS.monthly.iosStoreProductId,
      'ios'
    );
    
    const yearlyIOSCreated = await createProduct(
      SUBSCRIPTIONS.yearly.identifier,
      SUBSCRIPTIONS.yearly.iosStoreProductId,
      'ios'
    );

    // 3. Create Products for Android (if different IDs)
    if (SUBSCRIPTIONS.monthly.androidStoreProductId !== SUBSCRIPTIONS.monthly.iosStoreProductId) {
      await createProduct(
        SUBSCRIPTIONS.monthly.identifier,
        SUBSCRIPTIONS.monthly.androidStoreProductId,
        'android'
      );
    }
    
    if (SUBSCRIPTIONS.yearly.androidStoreProductId !== SUBSCRIPTIONS.yearly.iosStoreProductId) {
      await createProduct(
        SUBSCRIPTIONS.yearly.identifier,
        SUBSCRIPTIONS.yearly.androidStoreProductId,
        'android'
      );
    }

    // 4. Attach Products to Entitlement
    if (monthlyIOSCreated) {
      await attachProductToEntitlement(SUBSCRIPTIONS.monthly.identifier, 'ios');
    }
    if (yearlyIOSCreated) {
      await attachProductToEntitlement(SUBSCRIPTIONS.yearly.identifier, 'ios');
    }

    // 5. Create Offering
    await createOffering();

    // 6. Add Packages to Offering
    if (monthlyIOSCreated) {
      await addPackageToOffering(
        SUBSCRIPTIONS.monthly.identifier,
        SUBSCRIPTIONS.monthly.identifier,
        'ios'
      );
    }
    if (yearlyIOSCreated) {
      await addPackageToOffering(
        SUBSCRIPTIONS.yearly.identifier,
        SUBSCRIPTIONS.yearly.identifier,
        'ios'
      );
    }

    // 7. Set as Default Offering
    await setDefaultOffering();

    console.log('\n✨ RevenueCat setup completed successfully!');
    console.log('\n📋 Summary:');
    console.log(`   ✅ Entitlement: ${ENTITLEMENT_ID}`);
    console.log(`   ✅ Products: monthly, yearly`);
    console.log(`   ✅ Offering: ${OFFERING_ID} (set as default)`);
    console.log('\n💡 Next Steps:');
    console.log('   1. Verify in RevenueCat Dashboard that everything looks correct');
    console.log('   2. Make sure your App Store Connect subscriptions are created');
    console.log('   3. Test purchases in your app');
    
  } catch (error) {
    console.error('\n❌ Setup Failed:', error.message);
    process.exit(1);
  }
}

// Run the setup
setupRevenueCat();
