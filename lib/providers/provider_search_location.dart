import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Location of the most recent provider search in this app session.
///
/// The search screens used to start from the profile ZIP every time, so after
/// searching a new ZIP the hub and the next search still showed the old one.
/// They now read this first and fall back to the profile.
@immutable
class ProviderSearchLocation {
  const ProviderSearchLocation({
    required this.zip,
    required this.city,
    required this.radius,
  });

  final String zip;
  final String city;
  final int radius;

  static final ValueNotifier<ProviderSearchLocation?> lastSearched =
      ValueNotifier<ProviderSearchLocation?>(null);

  static void record({
    required String zip,
    required String city,
    required int radius,
  }) {
    if (zip.length != 5) return;
    lastSearched.value =
        ProviderSearchLocation(zip: zip, city: city, radius: radius);
  }

  /// Clears the session value. Not yet called on sign-out.
  static void reset() => lastSearched.value = null;
}

/// City name for a US ZIP via zippopotam.us; null when unknown or offline.
Future<String?> cityForZip(String zip) async {
  if (zip.length != 5) return null;
  try {
    final r = await http
        .get(Uri.parse('https://api.zippopotam.us/us/$zip'))
        .timeout(const Duration(seconds: 6));
    if (r.statusCode != 200) return null;
    final j = json.decode(r.body) as Map<String, dynamic>;
    final places = j['places'] as List<dynamic>?;
    if (places == null || places.isEmpty) return null;
    final first = places.first as Map<String, dynamic>;
    return first['place name'] as String?;
  } catch (_) {
    return null;
  }
}
