import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Create or update user profile
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await _usersCollection.doc(profile.userId).set(
            profile.toMap(),
            SetOptions(merge: true),
          );
      if (kDebugMode) {
        print('User profile saved successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user profile: $e');
      }
      rethrow;
    }
  }

  // Get user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user profile: $e');
      }
      rethrow;
    }
  }

  // Stream user profile changes
  Stream<UserProfile?> streamUserProfile(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Update specific fields
  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await _usersCollection.doc(userId).update(updates);
      if (kDebugMode) {
        print('User profile updated successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user profile: $e');
      }
      rethrow;
    }
  }

  // Delete user profile
  Future<void> deleteUserProfile(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
      if (kDebugMode) {
        print('User profile deleted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting user profile: $e');
      }
      rethrow;
    }
  }

  // Check if user profile exists
  Future<bool> userProfileExists(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      return doc.exists;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking user profile existence: $e');
      }
      return false;
    }
  }

  // Add a chronic condition
  Future<void> addChronicCondition(String userId, String condition) async {
    try {
      await _usersCollection.doc(userId).update({
        'chronicConditions': FieldValue.arrayUnion([condition]),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error adding chronic condition: $e');
      }
      rethrow;
    }
  }

  // Add a medication
  Future<void> addMedication(String userId, String medication) async {
    try {
      await _usersCollection.doc(userId).update({
        'medications': FieldValue.arrayUnion([medication]),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error adding medication: $e');
      }
      rethrow;
    }
  }

  // Add an allergy
  Future<void> addAllergy(String userId, String allergy) async {
    try {
      await _usersCollection.doc(userId).update({
        'allergies': FieldValue.arrayUnion([allergy]),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error adding allergy: $e');
      }
      rethrow;
    }
  }

  // Check if user has given consent
  Future<bool> userHasConsent(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) return false;
      
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return false;
      
      final consents = data['consents'] as Map<String, dynamic>?;
      if (consents == null) return false;
      
      return consents['termsAccepted'] == true && 
             consents['privacyAccepted'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking consent: $e');
      }
      return false;
    }
  }

  // Check if AI features are enabled
  Future<bool> areAIFeaturesEnabled(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) return true; // Default to enabled
      
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return true; // Default to enabled
      
      final privacySettings = data['privacySettings'] as Map<String, dynamic>?;
      if (privacySettings == null) return true; // Default to enabled
      
      return privacySettings['aiFeaturesEnabled'] as bool? ?? true; // Default to enabled
    } catch (e) {
      if (kDebugMode) {
        print('Error checking AI features: $e');
      }
      return true; // Default to enabled on error
    }
  }
}






