import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// Assuming you have a firebase_options.dart file for Firebase initialization
// import '../firebase_options.dart';

Future<void> main() async {
  // Ensure Firebase is initialized
  if (Firebase.apps.isEmpty) {
    // TODO: Replace with your actual Firebase options
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print('Firebase not initialized. Please initialize Firebase before running this script.');
    print('Example: await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);');
    return;
  }

  final firestore = FirebaseFirestore.instance;

  final List<Map<String, dynamic>> dummyCharities = [
    {
      'id': 'clean_water_fund',
      'name': 'Clean Water Fund',
      'description': 'Dedicated to providing clean and safe water to communities in need.',
      'emblemUrl': 'https://example.com/clean_water_emblem.png',
    },
    {
      'id': 'rainforest_alliance',
      'name': 'Rainforest Alliance',
      'description': 'Working to conserve biodiversity and ensure sustainable livelihoods.',
      'emblemUrl': 'https://example.com/rainforest_alliance_emblem.png',
    },
    {
      'id': 'doctors_without_borders',
      'name': 'Doctors Without Borders',
      'description': 'Provides humanitarian medical care in conflict zones and countries affected by endemic diseases.',
      'emblemUrl': 'https://example.com/msf_emblem.png',
    },
    {
      'id': 'world_wildlife_fund',
      'name': 'World Wildlife Fund',
      'description': 'An international non-governmental organization for wilderness preservation and the reduction of human impact on the environment.',
      'emblemUrl': 'https://example.com/wwf_emblem.png',
    },
    {
      'id': 'st_jude',
      'name': 'St. Jude Children\'s Research Hospital',
      'description': 'Leading the way the world understands, treats and defeats childhood cancer and other life-threatening diseases.',
      'emblemUrl': 'https://example.com/st_jude_emblem.png',
    },
    {
      'id': 'red_cross',
      'name': 'American Red Cross',
      'description': 'Prevents and alleviates human suffering in the face of emergencies by mobilizing the power of volunteers and the generosity of donors.',
      'emblemUrl': 'https://example.com/red_cross_emblem.png',
    },
  ];

  print('Populating Firestore with dummy charity data...');

  for (final charityData in dummyCharities) {
    try {
      await firestore.collection('charities').doc(charityData['id']).set(charityData);
      print('Added charity: ${charityData['name']}');
    } catch (e) {
      print('Error adding charity ${charityData['name']}: $e');
    }
  }

  print('Finished populating charity data.');
}
