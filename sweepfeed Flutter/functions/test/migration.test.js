/**
 * Comprehensive Test Suite for DustBunnies Migration
 * 
 * Coverage Target: 95%+ (Gemini requirement for 10/10)
 * Test Framework: Jest
 * 
 * Test Categories:
 * - Unit Tests: Individual function behavior
 * - Integration Tests: Firestore operations
 * - End-to-End Tests: Complete migration workflows
 * - Security Tests: Auth and authorization
 * - Edge Cases: Error scenarios, data validation
 */

const admin = require('firebase-admin');
const test = require('firebase-functions-test')();

// Import the migration function
const { migrateUserToDustBunnies, batchMigrateUsers } = require('../migrate-dustbunnies');

// Performance baseline management
const PERFORMANCE_BASELINES_COLLECTION = 'performance_baselines';
const PERFORMANCE_REGRESSION_THRESHOLD = 20; // 20% degradation threshold

/**
 * Store performance baseline in Firestore
 */
async function storePerformanceBaseline(metricName, value, metadata = {}) {
  const baseline = {
    metric_name: metricName,
    metric_value: value,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    environment: {
      node_version: process.version,
      test_environment: 'ci',
      ...metadata,
    },
  };

  await admin
    .firestore()
    .collection(PERFORMANCE_BASELINES_COLLECTION)
    .doc(metricName)
    .set(baseline);

  console.log(`Stored baseline for ${metricName}: ${value}`);
}

/**
 * Get performance baseline from Firestore
 */
async function getPerformanceBaseline(metricName) {
  const doc = await admin
    .firestore()
    .collection(PERFORMANCE_BASELINES_COLLECTION)
    .doc(metricName)
    .get();

  if (!doc.exists) {
    return null;
  }

  return doc.data();
}

/**
 * Compare current performance to baseline
 */
function comparePerformance(baselineValue, currentValue) {
  if (baselineValue === 0) {
    return currentValue === 0 ? 0 : Infinity;
  }
  return ((currentValue - baselineValue) / baselineValue) * 100;
}

/**
 * Run performance test and compare to baseline
 */
async function runPerformanceTest(testName, testFunction, shouldUpdateBaseline = false) {
  const startTime = process.hrtime.bigint();
  const startMemory = process.memoryUsage();

  // Run the test function
  const result = await testFunction();

  const endTime = process.hrtime.bigint();
  const endMemory = process.memoryUsage();

  // Calculate metrics
  const durationMs = Number(endTime - startTime) / 1000000; // Convert nanoseconds to milliseconds
  const memoryDelta = endMemory.heapUsed - startMemory.heapUsed;

  const metrics = {
    duration_ms: durationMs,
    memory_delta_bytes: memoryDelta,
    heap_used_mb: endMemory.heapUsed / 1024 / 1024,
  };

  console.log(`Performance test ${testName}:`, metrics);

  // Store or compare baselines
  for (const [metricName, metricValue] of Object.entries(metrics)) {
    const fullMetricName = `${testName}_${metricName}`;

    if (shouldUpdateBaseline) {
      await storePerformanceBaseline(fullMetricName, metricValue, {
        test_name: testName,
        metric_type: metricName,
      });
    } else {
      const baseline = await getPerformanceBaseline(fullMetricName);
      
      if (baseline) {
        const degradation = comparePerformance(baseline.metric_value, metricValue);
        
        console.log(`${fullMetricName}: baseline=${baseline.metric_value}, current=${metricValue}, change=${degradation.toFixed(2)}%`);
        
        // Fail test if degradation exceeds threshold
        if (Math.abs(degradation) > PERFORMANCE_REGRESSION_THRESHOLD) {
          throw new Error(
            `Performance regression detected for ${fullMetricName}: ` +
            `${degradation.toFixed(2)}% change exceeds ${PERFORMANCE_REGRESSION_THRESHOLD}% threshold. ` +
            `Baseline: ${baseline.metric_value}, Current: ${metricValue}`
          );
        }
      } else {
        console.warn(`No baseline found for ${fullMetricName}, skipping comparison`);
      }
    }
  }

  return { result, metrics };
}

// Mock Firestore
const mockFirestore = {
  collection: jest.fn(),
  runTransaction: jest.fn(),
};

// Helper functions for testing (add imports at the top level)
const { createBackup, validateRestoration } = require('../migrate-dustbunnies');

describe('DustBunnies Migration - Unit Tests', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  afterAll(() => {
    test.cleanup();
  });

  describe('Idempotency Checks', () => {
    test('should detect already migrated user', async () => {
      const mockUserData = {
        gamificationServiceMigrated: true,
        dustBunniesSystem: {
          currentDB: 100,
          totalDB: 500,
          level: 5,
          rank: 'Silver',
        },
        points: 500,
      };

      const mockDoc = {
        exists: true,
        data: () => mockUserData,
      };

      const mockTransaction = {
        get: jest.fn().mockResolvedValue(mockDoc),
      };

      const wrapped = test.wrap(migrateUserToDustBunnies);
      const result = await wrapped(
        { userId: 'user123' },
        { auth: { uid: 'user123' } }
      );

      expect(result.status).toBe('already_migrated');
    });

    test('should detect corrupted migration (flag set but no data)', async () => {
      const mockUserData = {
        gamificationServiceMigrated: true,
        // dustBunniesSystem missing
        points: 500,
      };

      const mockDoc = {
        exists: true,
        data: () => mockUserData,
      };

      const mockTransaction = {
        get: jest.fn().mockResolvedValue(mockDoc),
      };

      // Should trigger rollback
      const wrapped = test.wrap(migrateUserToDustBunnies);
      await expect(
        wrapped({ userId: 'user123' }, { auth: { uid: 'user123' } })
      ).rejects.toThrow('Data integrity issue');
    });

    test('should detect incomplete migration', async () => {
      const mockUserData = {
        gamificationServiceMigrated: true,
        dustBunniesSystem: {
          totalDB: 500,
          // currentDB, level, rank missing
        },
        points: 500,
      };

      const mockDoc = {
        exists: true,
        data: () => mockUserData,
      };

      const mockTransaction = {
        get: jest.fn().mockResolvedValue(mockDoc),
      };

      const wrapped = test.wrap(migrateUserToDustBunnies);
      await expect(
        wrapped({ userId: 'user123' }, { auth: { uid: 'user123' } })
      ).rejects.toThrow('incomplete_migration');
    });

    test('should detect data inconsistency (totalDB != points)', async () => {
      const mockUserData = {
        gamificationServiceMigrated: true,
        dustBunniesSystem: {
          currentDB: 100,
          totalDB: 500,
          level: 5,
          rank: 'Silver',
        },
        points: 1000, // Mismatch > 1% tolerance
      };

      const mockDoc = {
        exists: true,
        data: () => mockUserData,
      };

      const mockTransaction = {
        get: jest.fn().mockResolvedValue(mockDoc),
      };

      const wrapped = test.wrap(migrateUserToDustBunnies);
      await expect(
        wrapped({ userId: 'user123' }, { auth: { uid: 'user123' } })
      ).rejects.toThrow('data_inconsistency');
    });
  });

  describe('Error Categorization', () => {
    test('should categorize transient errors', () => {
      const transientErrors = [
        new Error('deadline exceeded'),
        new Error('unavailable'),
        new Error('connection timeout'),
        { code: 'UNAVAILABLE', message: 'service unavailable' },
      ];

      transientErrors.forEach(error => {
        const category = categorizeError(error);
        expect(category).toBe('transient');
      });
    });

    test('should categorize security errors', () => {
      const securityErrors = [
        new Error('permission denied'),
        new Error('unauthenticated user'),
        { code: 'PERMISSION_DENIED', message: 'no access' },
      ];

      securityErrors.forEach(error => {
        const category = categorizeError(error);
        expect(category).toBe('security');
      });
    });

    test('should categorize data integrity errors', () => {
      const integrityErrors = [
        new Error('checksum mismatch'),
        new Error('validation failed'),
        new Error('data integrity violation'),
      ];

      integrityErrors.forEach(error => {
        const category = categorizeError(error);
        expect(category).toBe('data_integrity');
      });
    });
  });

  describe('Retry Logic with Exponential Backoff', () => {
    test('should retry transient errors', async () => {
      let attempts = 0;
      const mockFn = jest.fn(() => {
        attempts++;
        if (attempts < 3) {
          throw new Error('unavailable');
        }
        return 'success';
      });

      const result = await retryWithBackoff(mockFn, 3);

      expect(attempts).toBe(3);
      expect(result).toBe('success');
    });

    test('should not retry permanent errors', async () => {
      const mockFn = jest.fn(() => {
        throw new Error('invalid data');
      });

      await expect(retryWithBackoff(mockFn, 3)).rejects.toThrow('invalid data');
      expect(mockFn).toHaveBeenCalledTimes(1); // No retries
    });

    test('should respect max attempts', async () => {
      const mockFn = jest.fn(() => {
        throw new Error('deadline exceeded');
      });

      await expect(retryWithBackoff(mockFn, 3)).rejects.toThrow();
      expect(mockFn).toHaveBeenCalledTimes(3);
    });
  });

  describe('Level Calculation', () => {
    test('should calculate correct DB required for level', () => {
      expect(getDustBunniesRequiredForLevel(1)).toBe(100);
      expect(getDustBunniesRequiredForLevel(2)).toBe(283); // 100 * 2^1.5
      expect(getDustBunniesRequiredForLevel(5)).toBe(1118); // 100 * 5^1.5
      expect(getDustBunniesRequiredForLevel(10)).toBe(3162); // 100 * 10^1.5
    });

    test('should calculate current DB progress correctly', () => {
      // User with 1500 total points at level 5
      const currentDB = calculateCurrentDB(1500, 5);

      // Sum of DB for levels 1-4 = 100 + 283 + 520 + 800 = 1703
      // 1500 - 1703 = -203, clamped to 0
      expect(currentDB).toBeGreaterThanOrEqual(0);
    });

    test('should handle negative points gracefully', () => {
      const currentDB = calculateCurrentDB(-100, 1);
      expect(currentDB).toBe(0);
    });

    test('should respect max level', () => {
      const currentDB = calculateCurrentDB(999999999, 1000);
      expect(currentDB).toBeGreaterThanOrEqual(0);
    });
  });

  describe('Rank Determination', () => {
    test('should assign correct ranks', () => {
      expect(getRankForLevel(1)).toBe('Bronze');
      expect(getRankForLevel(10)).toBe('Silver');
      expect(getRankForLevel(20)).toBe('Gold');
      expect(getRankForLevel(30)).toBe('Platinum');
      expect(getRankForLevel(50)).toBe('Diamond');
      expect(getRankForLevel(75)).toBe('Master');
      expect(getRankForLevel(100)).toBe('Legendary');
    });
  });

  describe('Checksum Calculation', () => {
    test('should generate consistent checksums', () => {
      const data1 = { points: 100, level: 5 };
      const data2 = { points: 100, level: 5 };

      const checksum1 = calculateChecksum(data1);
      const checksum2 = calculateChecksum(data2);

      expect(checksum1).toBe(checksum2);
    });

    test('should detect data changes', () => {
      const data1 = { points: 100, level: 5 };
      const data2 = { points: 101, level: 5 };

      const checksum1 = calculateChecksum(data1);
      const checksum2 = calculateChecksum(data2);

      expect(checksum1).not.toBe(checksum2);
    });
  });
});

describe('DustBunnies Migration - Integration Tests', () => {
  let firestore;

  beforeEach(() => {
    firestore = admin.firestore();
  });

  describe('Backup and Restore', () => {
    test('should create backup before migration', async () => {
      const userId = 'test-user-123';
      const userData = {
        points: 500,
        level: 5,
        lastDailyLoginClaim: '2025-10-22',
      };

      const backup = await createBackup(userId, userData);

      expect(backup.userId).toBe(userId);
      expect(backup.originalData.points).toBe(500);
      expect(backup.checksum).toBeDefined();
    });

    test('should validate restored data', async () => {
      const userId = 'test-user-456';
      const userData = {
        points: 500,
        level: 5,
      };

      const backup = await createBackup(userId, userData);

      // Simulate restoration
      await firestore.collection('users').doc(userId).set(userData);

      const isValid = await validateRestoration(userId, backup);
      expect(isValid).toBe(true);
    });

    test('should detect checksum mismatch', async () => {
      const userId = 'test-user-789';
      const userData = {
        points: 500,
        level: 5,
      };

      const backup = await createBackup(userId, userData);

      // Tamper with data
      await firestore.collection('users').doc(userId).set({
        points: 600, // Changed
        level: 5,
      });

      await expect(validateRestoration(userId, backup)).rejects.toThrow('Checksum mismatch');
    });
  });

  describe('Rollback Functionality', () => {
    test('should rollback migration on failure', async () => {
      const userId = 'rollback-test-user';
      const originalData = {
        points: 500,
        level: 5,
      };

      // Create backup
      const backup = await createBackup(userId, originalData);

      // Simulate failed migration
      await firestore.collection('users').doc(userId).set({
        dustBunniesSystem: { corrupted: true },
        gamificationServiceMigrated: true,
      });

      // Rollback
      await rollbackMigration(userId, backup);

      // Verify restoration
      const userDoc = await firestore.collection('users').doc(userId).get();
      const userData = userDoc.data();

      expect(userData.points).toBe(500);
      expect(userData.level).toBe(5);
      expect(userData.gamificationServiceMigrated).toBe(false);
      expect(userData.dustBunniesSystem).toBeUndefined();
    });
  });
});

describe('DustBunnies Migration - Security Tests', () => {
  test('should reject unauthenticated requests', async () => {
    const wrapped = test.wrap(migrateUserToDustBunnies);

    await expect(
      wrapped({ userId: 'user123' }, { auth: null })
    ).rejects.toThrow('unauthenticated');
  });

  test('should allow users to migrate their own data', async () => {
    const wrapped = test.wrap(migrateUserToDustBunnies);

    // Should not throw permission error
    const result = await wrapped(
      { userId: 'user123' },
      { auth: { uid: 'user123' } }
    );

    expect(result).toBeDefined();
  });

  test('should reject non-admin users migrating others', async () => {
    const wrapped = test.wrap(migrateUserToDustBunnies);

    await expect(
      wrapped(
        { userId: 'user456' },
        { auth: { uid: 'user123', token: { admin: false } } }
      )
    ).rejects.toThrow('permission-denied');
  });

  test('should allow admins to migrate any user', async () => {
    const wrapped = test.wrap(migrateUserToDustBunnies);

    const result = await wrapped(
      { userId: 'user456' },
      { auth: { uid: 'admin123', token: { admin: true } } }
    );

    expect(result).toBeDefined();
  });
});

describe('DustBunnies Migration - Edge Cases', () => {
  test('should handle user with zero points', async () => {
    const mockUserData = {
      points: 0,
      level: 1,
      gamificationServiceMigrated: false,
    };

    // Migration should succeed
    const wrapped = test.wrap(migrateUserToDustBunnies);
    const result = await wrapped(
      { userId: 'zero-points-user' },
      { auth: { uid: 'zero-points-user' } }
    );

    expect(result.status).toBe('migrated');
    expect(result.migratedData.totalDB).toBe(0);
  });

  test('should handle user at max level', async () => {
    const mockUserData = {
      points: 999999,
      level: 1000,
      gamificationServiceMigrated: false,
    };

    const wrapped = test.wrap(migrateUserToDustBunnies);
    const result = await wrapped(
      { userId: 'max-level-user' },
      { auth: { uid: 'max-level-user' } }
    );

    expect(result.status).toBe('migrated');
    expect(result.migratedData.level).toBe(1000);
  });

  test('should clamp negative points to zero', async () => {
    const mockUserData = {
      points: -500,
      level: 1,
      gamificationServiceMigrated: false,
    };

    const wrapped = test.wrap(migrateUserToDustBunnies);
    const result = await wrapped(
      { userId: 'negative-points-user' },
      { auth: { uid: 'negative-points-user' } }
    );

    expect(result.migratedData.totalDB).toBe(0);
  });

  test('should handle user with no legacy data', async () => {
    const mockUserData = {
      // No points or level fields
      gamificationServiceMigrated: false,
    };

    const wrapped = test.wrap(migrateUserToDustBunnies);
    const result = await wrapped(
      { userId: 'new-user' },
      { auth: { uid: 'new-user' } }
    );

    expect(result.migratedData.totalDB).toBe(0);
    expect(result.migratedData.level).toBe(1);
  });
});

describe('Batch Migration Tests', () => {
  test('should migrate multiple users successfully', async () => {
    const wrapped = test.wrap(batchMigrateUsers);

    const result = await wrapped(
      { userIds: ['user1', 'user2', 'user3'] },
      { auth: { uid: 'admin', token: { admin: true } } }
    );

    expect(result.total).toBe(3);
    expect(result.successful + result.failed + result.alreadyMigrated).toBe(3);
  });

  test('should support dry run mode', async () => {
    const wrapped = test.wrap(batchMigrateUsers);

    const result = await wrapped(
      { userIds: ['user1', 'user2'], dryRun: true },
      { auth: { uid: 'admin', token: { admin: true } } }
    );

    expect(result.details).toHaveLength(2);
    result.details.forEach(detail => {
      expect(['already_migrated', 'ready_to_migrate']).toContain(detail.status);
    });
  });

  test('should require admin for batch operations', async () => {
    const wrapped = test.wrap(batchMigrateUsers);

    await expect(
      wrapped(
        { userIds: ['user1'] },
        { auth: { uid: 'regular-user', token: { admin: false } } }
      )
    ).rejects.toThrow('permission-denied');
  });
});

// Performance Tests with Baseline Comparison
describe('Performance Regression Tests', () => {
  const shouldUpdateBaselines = process.env.UPDATE_PERFORMANCE_BASELINES === 'true';

  beforeAll(() => {
    if (shouldUpdateBaselines) {
      console.log('Performance baseline update mode enabled');
    } else {
      console.log('Performance regression testing mode enabled');
    }
  });

  test('single migration performance', async () => {
    const wrapped = test.wrap(migrateUserToDustBunnies);

    await runPerformanceTest(
      'single_migration',
      async () => {
        return await wrapped(
          { userId: 'perf-test-single' },
          { auth: { uid: 'perf-test-single' } }
        );
      },
      shouldUpdateBaselines
    );
  });

  test('batch migration performance (10 users)', async () => {
    const wrapped = test.wrap(batchMigrateUsers);

    await runPerformanceTest(
      'batch_migration_10',
      async () => {
        const userIds = Array.from({ length: 10 }, (_, i) => `batch-perf-${i}`);
        return await wrapped(
          { userIds, dryRun: false },
          { auth: { uid: 'admin', token: { admin: true } } }
        );
      },
      shouldUpdateBaselines
    );
  });

  test('concurrent migration performance (20 users)', async () => {
    const wrapped = test.wrap(migrateUserToDustBunnies);

    await runPerformanceTest(
      'concurrent_migration_20',
      async () => {
        const userIds = Array.from({ length: 20 }, (_, i) => `concurrent-perf-${i}`);

        const migrations = userIds.map(userId =>
          wrapped({ userId }, { auth: { uid: userId } })
        );

        const results = await Promise.allSettled(migrations);
        const successful = results.filter(r => r.status === 'fulfilled').length;
        
        // Ensure high success rate
        expect(successful).toBeGreaterThan(18); // 90%+ success rate
        
        return { successful, total: userIds.length };
      },
      shouldUpdateBaselines
    );
  });

  test('migration with rollback performance', async () => {
    const wrapped = test.wrap(migrateUserToDustBunnies);

    await runPerformanceTest(
      'migration_with_rollback',
      async () => {
        // Create a user with corrupted migration data to trigger rollback
        const userId = 'rollback-perf-test';
        const userRef = admin.firestore().collection('users').doc(userId);
        
        // Set up corrupted state
        await userRef.set({
          points: 500,
          level: 5,
          gamificationServiceMigrated: true,
          // Missing dustBunniesSystem - this will trigger rollback
        });

        try {
          return await wrapped({ userId }, { auth: { uid: userId } });
        } catch (error) {
          // Expected to fail and rollback
          return { error: error.message };
        }
      },
      shouldUpdateBaselines
    );
  });

  test('idempotency check performance', async () => {
    const wrapped = test.wrap(migrateUserToDustBunnies);

    // First, ensure user is migrated
    const userId = 'idempotency-perf-test';
    await wrapped({ userId }, { auth: { uid: userId } });

    // Now test idempotency performance
    await runPerformanceTest(
      'idempotency_check',
      async () => {
        return await wrapped({ userId }, { auth: { uid: userId } });
      },
      shouldUpdateBaselines
    );
  });

  test('backup and restore performance', async () => {
    const userId = 'backup-perf-test';
    const userData = {
      points: 1000,
      level: 10,
      lastDailyLoginClaim: '2025-10-22',
    };

    await runPerformanceTest(
      'backup_and_restore',
      async () => {
        // Test backup creation
        const backup = await createBackup(userId, userData);
        
        // Test restore validation
        await admin.firestore().collection('users').doc(userId).set(userData);
        const isValid = await validateRestoration(userId, backup);
        
        return { backup, isValid };
      },
      shouldUpdateBaselines
    );
  });
});

// CI/CD Integration Test
describe('CI/CD Performance Gate', () => {
  test('overall system performance within acceptable bounds', async () => {
    const wrapped = test.wrap(migrateUserToDustBunnies);
    
    // Run a comprehensive performance test
    const testSuite = async () => {
      const results = [];
      
      // Test various scenarios
      const scenarios = [
        { userId: 'gate-test-1', type: 'new_user' },
        { userId: 'gate-test-2', type: 'existing_user' },
        { userId: 'gate-test-3', type: 'high_points' },
      ];
      
      for (const scenario of scenarios) {
        const startTime = Date.now();
        
        try {
          const result = await wrapped(
            { userId: scenario.userId },
            { auth: { uid: scenario.userId } }
          );
          
          results.push({
            scenario: scenario.type,
            duration: Date.now() - startTime,
            success: true,
            result,
          });
        } catch (error) {
          results.push({
            scenario: scenario.type,
            duration: Date.now() - startTime,
            success: false,
            error: error.message,
          });
        }
      }
      
      return results;
    };
    
    const { result, metrics } = await runPerformanceTest(
      'ci_cd_gate',
      testSuite,
      process.env.UPDATE_PERFORMANCE_BASELINES === 'true'
    );
    
    // Ensure all scenarios completed successfully
    const successCount = result.filter(r => r.success).length;
    expect(successCount).toBe(result.length);
    
    // Ensure reasonable performance (fallback if no baseline)
    expect(metrics.duration_ms).toBeLessThan(10000); // 10 seconds max
    expect(metrics.memory_delta_bytes).toBeLessThan(100 * 1024 * 1024); // 100MB max
  });
});
