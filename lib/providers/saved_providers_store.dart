import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/provider.dart';

/// One bookmarked provider, read back from Firestore.
class SavedProvider {
  const SavedProvider({
    required this.docId,
    required this.provider,
    this.savedAt,
  });

  final String docId;

  /// Null for older bookmarks that only stored a provider id.
  final Provider? provider;
  final DateTime? savedAt;
}

/// Bookmarks live at `users/{uid}/saved_providers/{docId}`, the same path
/// [ProviderRepository.saveProvider] writes and firestore.rules allows for the
/// owner. Search results are often not Firestore providers, so each bookmark
/// keeps a snapshot of the listing; otherwise the list could not show them.
class SavedProvidersStore {
  SavedProvidersStore({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _firestore.collection('users').doc(uid).collection('saved_providers');

  /// Stable bookmark id: NPI first (the same provider can arrive with or
  /// without a Firestore id depending on the screen), then Firestore id, then
  /// name + location. Slashes are not allowed in document ids.
  static String docIdFor(Provider p) {
    String raw;
    final id = (p.id ?? '').trim();
    final npi = (p.npi ?? '').trim();
    if (npi.isNotEmpty) {
      raw = 'npi_$npi';
    } else if (id.isNotEmpty) {
      raw = id;
    } else {
      final namePart =
          p.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
      if (p.locations.isNotEmpty) {
        final loc = p.locations.first;
        raw = 'api_${namePart}_${loc.city}_${loc.zip}';
      } else {
        raw = 'name_$namePart';
      }
    }
    return raw.replaceAll('/', '_');
  }

  Future<bool> isSaved(String uid, String docId) async {
    final doc = await _col(uid).doc(docId).get();
    return doc.exists;
  }

  Future<void> save(String uid, Provider p, {String? docId}) {
    final data = p.toMap()
      ..remove('createdAt')
      ..remove('updatedAt');
    return _col(uid).doc(docId ?? docIdFor(p)).set({
      'savedAt': FieldValue.serverTimestamp(),
      'firestoreId': p.id,
      'provider': data,
    });
  }

  Future<void> remove(String uid, String docId) =>
      _col(uid).doc(docId).delete();

  /// Newest first.
  Stream<List<SavedProvider>> watch(String uid) {
    return _col(uid)
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  static SavedProvider _fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    Provider? provider;
    final raw = data['provider'];
    if (raw is Map) {
      try {
        final map = Map<String, dynamic>.from(
          raw.map((k, v) => MapEntry(k.toString(), v)),
        );
        final fid = data['firestoreId'];
        provider = Provider.fromMap(
          map,
          id: fid is String && fid.isNotEmpty ? fid : null,
        );
      } catch (_) {
        provider = null;
      }
    }
    final ts = data['savedAt'];
    return SavedProvider(
      docId: doc.id,
      provider: provider,
      savedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
