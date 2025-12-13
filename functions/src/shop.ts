import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

// TODO: Move this to a shared model
enum ShopItemType {
  avatarFrame,
  badge,
  background,
  theme,
  title,
  emoji,
  animation,
  sticker,
}

// TODO: Move this to a shared model
enum ShopItemRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  mythic,
}

// TODO: Move this to a shared model
class ShopItem {
  constructor(
      public id: string,
      public name: string,
      public description: string,
      public type: ShopItemType,
      public rarity: ShopItemRarity,
      public price: number,
      public imageUrl: string,
      public isLimited: boolean,
      public isOwned: boolean,
      public isEquipped: boolean,
      public properties: {[key: string]: any},
      public tags: string[],
      public limitedUntil?: Date,
  ) {}
}

export const getShopItems = functions.https.onCall(async (data, context) => {
  // In a real app, you would fetch this from Firestore
  const now = new Date();
  const items = [
    new ShopItem(
        'frame_neon_glow',
        'Neon Glow Frame',
        'A vibrant neon frame that pulses with energy',
        ShopItemType.avatarFrame,
        ShopItemRarity.rare,
        150,
        'https://example.com/frames/neon_glow.png',
        false,
        false,
        false,
        {'glow_color': 'cyan', 'animation': 'pulse'},
        ['glow', 'animated', 'popular'],
    ),
    new ShopItem(
        'frame_fire_border',
        'Fire Border',
        'Blazing flames surround your avatar',
        ShopItemType.avatarFrame,
        ShopItemRarity.epic,
        300,
        'https://example.com/frames/fire_border.png',
        false,
        true,
        true,
        {'flame_intensity': 'high', 'color_scheme': 'orange_red'},
        ['fire', 'epic', 'animated'],
    ),
    new ShopItem(
        'frame_cyber_monday',
        'Cyber Monday Special',
        'Exclusive digital circuit frame - limited time only!',
        ShopItemType.avatarFrame,
        ShopItemRarity.legendary,
        500,
        'https://example.com/frames/cyber_monday.png',
        true,
        false,
        false,
        {
          'circuit_pattern': 'digital',
          'special_event': 'cyber_monday',
        },
        ['limited', 'legendary', 'tech', 'exclusive'],
        new Date(now.getTime() + 24 * 60 * 60 * 1000),
    ),
  ];

  return items;
});

export const purchaseShopItem = functions.https.onCall(async (data, context) => {
  const itemId = data.itemId;
  const userId = context.auth?.uid;

  if (!userId) {
    throw new functions.https.HttpsError(
        'unauthenticated',
        'The function must be called while authenticated.',
    );
  }

  const db = admin.firestore();

  const itemRef = db.collection('shopItems').doc(itemId);
  const userRef = db.collection('users').doc(userId);

  return db.runTransaction(async (transaction) => {
    const itemDoc = await transaction.get(itemRef);
    const userDoc = await transaction.get(userRef);

    if (!itemDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Item not found');
    }

    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }

    const item = itemDoc.data() as ShopItem;
    const user = userDoc.data();

    if (user?.dustBunniesSystem.currentDB < item.price) {
      throw new functions.https.HttpsError(
          'failed-precondition',
          'Insufficient DustBunnies',
      );
    }

    const newBalance = user?.dustBunniesSystem.currentDB - item.price;

    transaction.update(userRef, {'dustBunniesSystem.currentDB': newBalance});
    transaction.set(
        userRef.collection('inventory').doc(itemId),
        item,
    );

    return {success: true};
  });
});