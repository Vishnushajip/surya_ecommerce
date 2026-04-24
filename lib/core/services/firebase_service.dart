import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();

  FirebaseService._();

  late final FirebaseFirestore _firestore;
  late final FirebaseStorage _storage;

  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: kIsWeb ? getWebOptions() : getMobileOptions(),
      );

      _firestore = FirebaseFirestore.instance;
      _storage = FirebaseStorage.instance;


      debugPrint('✅ Firebase initialized successfully');
    } catch (e) {
      debugPrint('❌ Firebase initialization failed: $e');
      rethrow;
    }
  }

  FirebaseOptions getWebOptions() {
    return const FirebaseOptions(
      apiKey: AppConstants.firebaseApiKey,
      authDomain: AppConstants.firebaseAuthDomain,
      projectId: AppConstants.firebaseProjectId,
      storageBucket: AppConstants.firebaseStorageBucket,
      messagingSenderId: AppConstants.firebaseMessagingSenderId,
      appId: AppConstants.firebaseAppId,
      measurementId: AppConstants.firebaseMeasurementId,
    );
  }

  FirebaseOptions getMobileOptions() {
    return const FirebaseOptions(
      apiKey: AppConstants.firebaseApiKey,
      appId: AppConstants.firebaseAppId,
      messagingSenderId: AppConstants.firebaseMessagingSenderId,
      projectId: AppConstants.firebaseProjectId,
      storageBucket: AppConstants.firebaseStorageBucket,
    );
  }

  CollectionReference get productsCollection =>
      _firestore.collection('products');
  CollectionReference get feedbackCollection =>
      _firestore.collection('product_feedback');
  CollectionReference get ordersCollection => _firestore.collection('orders');

  Future<bool> checkConnection() async {
    try {
      await _firestore.collection('connection_test').limit(1).get();
      return true;
    } catch (e) {
      debugPrint('❌ Firebase connection check failed: $e');
      return false;
    }
  }

  Future<void> enableOfflinePersistence() async {
    try {
      await _firestore.enableNetwork();
      debugPrint('✅ Network enabled for Firestore');
    } catch (e) {
      debugPrint('❌ Failed to enable network: $e');
    }
  }

  Future<void> disableNetwork() async {
    try {
      await _firestore.disableNetwork();
      debugPrint('✅ Network disabled for Firestore');
    } catch (e) {
      debugPrint('❌ Failed to disable network: $e');
    }
  }
}
