import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NearestContactsService {
  static const double _earthRadiusKm = 6371.0;

  /// Haversine formula — returns distance in kilometres between two GPS points.
  static double haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  static double _toRad(double deg) => deg * pi / 180.0;

  /// Persist the current user's location to their Firestore document.
  static Future<void> updateUserLocation(double lat, double lng) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'latitude': lat,
      'longitude': lng,
      'locationUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Fetch all registered users and return those within [radiusKm] of the
  /// given coordinates, sorted by ascending distance (nearest first).
  /// The caller's own UID is excluded automatically.
  static Future<List<Map<String, dynamic>>> findNearestUsers({
    required double senderLat,
    required double senderLng,
    double radiusKm = 5.0,
    int limit = 10,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    final snapshot = await FirebaseFirestore.instance.collection('users').get();

    final List<Map<String, dynamic>> nearby = [];

    for (final doc in snapshot.docs) {
      if (doc.id == currentUid) continue;

      final data = doc.data();
      final double? lat = (data['latitude'] as num?)?.toDouble();
      final double? lng = (data['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      final distance = haversineDistance(senderLat, senderLng, lat, lng);
      if (distance <= radiusKm) {
        nearby.add({
          'uid': doc.id,
          'name': data['name'] ?? 'Unknown',
          'phone': data['phoneNumber'] ?? '',
          'fcmToken': data['fcmToken'],
          'distanceKm': double.parse(distance.toStringAsFixed(2)),
        });
      }
    }

    nearby.sort(
      (a, b) =>
          (a['distanceKm'] as double).compareTo(b['distanceKm'] as double),
    );
    return nearby.take(limit).toList();
  }
}
