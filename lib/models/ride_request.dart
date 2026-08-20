import 'package:flutter/material.dart';

enum RideType { solo, couple, family }

extension RideTypeX on RideType {
  String get label => switch (this) {
    RideType.solo => '1 Person',
    RideType.couple => 'Couple',
    RideType.family => 'Family',
  };

  IconData get icon => switch (this) {
    RideType.solo => Icons.person_outline,
    RideType.couple => Icons.people_outline,
    RideType.family => Icons.family_restroom,
  };
}

RideType rideTypeFromString(String? value) => RideType.values.firstWhere(
  (t) => t.name == value,
  orElse: () => RideType.solo,
);

enum PaymentMethod { cash, easypaisa, jazzcash, bank }

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.cash => 'Cash',
    PaymentMethod.easypaisa => 'EasyPaisa',
    PaymentMethod.jazzcash => 'JazzCash',
    PaymentMethod.bank => 'Other Bank',
  };

  IconData get icon => switch (this) {
    PaymentMethod.cash => Icons.payments_outlined,
    PaymentMethod.easypaisa => Icons.account_balance_wallet_outlined,
    PaymentMethod.jazzcash => Icons.smartphone_outlined,
    PaymentMethod.bank => Icons.account_balance_outlined,
  };
}

PaymentMethod paymentMethodFromString(String? value) => PaymentMethod.values
    .firstWhere((m) => m.name == value, orElse: () => PaymentMethod.cash);

class RideRequest {
  final String id;
  final String riderInitials;
  final String riderName;
  final String pickup;
  final String dropoff;
  final double distanceKm;
  final int proposedPrice;
  final double pickupLat;
  final double pickupLng;
  final double dropLat;
  final double dropLng;
  final RideType rideType;
  final PaymentMethod paymentMethod;
  final int requestedAtMs;
  // 'female' or 'any'. Passenger service stays women-only either way — this
  // only controls whether age-verified male drivers (45-50) may also offer,
  // for riders who'd rather not wait for a female driver to be free.
  final String preferredDriverGender;

  const RideRequest({
    required this.id,
    required this.riderInitials,
    required this.riderName,
    required this.pickup,
    required this.dropoff,
    required this.distanceKm,
    required this.proposedPrice,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropLat,
    required this.dropLng,
    this.rideType = RideType.solo,
    this.paymentMethod = PaymentMethod.cash,
    this.requestedAtMs = 0,
    this.preferredDriverGender = 'female',
  });

  factory RideRequest.fromJson(Map<String, dynamic> json) => RideRequest(
    id: json['id'] as String,
    riderInitials: json['riderInitials'] as String? ?? '??',
    riderName: json['riderName'] as String? ?? 'Rider',
    pickup: json['pickup'] as String? ?? '',
    dropoff: json['dropoff'] as String? ?? '',
    distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
    proposedPrice: (json['proposedPrice'] as num?)?.toInt() ?? 0,
    pickupLat: (json['pickupLat'] as num?)?.toDouble() ?? 24.8607,
    pickupLng: (json['pickupLng'] as num?)?.toDouble() ?? 67.0011,
    dropLat: (json['dropLat'] as num?)?.toDouble() ?? 24.8607,
    dropLng: (json['dropLng'] as num?)?.toDouble() ?? 67.0011,
    rideType: rideTypeFromString(json['rideType'] as String?),
    paymentMethod: paymentMethodFromString(json['paymentMethod'] as String?),
    // Missing on any request that predates this field (stale entries that
    // have been sitting in the relay's memory since before this fix) —
    // defaulting to 0 makes them look infinitely old, so the staleness
    // filter below discards them instead of treating them as live.
    requestedAtMs: (json['requestedAtMs'] as num?)?.toInt() ?? 0,
    preferredDriverGender:
        json['preferredDriverGender'] as String? ?? 'female',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'riderInitials': riderInitials,
    'riderName': riderName,
    'pickup': pickup,
    'dropoff': dropoff,
    'distanceKm': distanceKm,
    'proposedPrice': proposedPrice,
    'pickupLat': pickupLat,
    'pickupLng': pickupLng,
    'dropLat': dropLat,
    'dropLng': dropLng,
    'rideType': rideType.name,
    'paymentMethod': paymentMethod.name,
    'requestedAtMs': requestedAtMs,
    'preferredDriverGender': preferredDriverGender,
  };

  bool get isStale =>
      requestedAtMs <= 0 ||
      DateTime.now().millisecondsSinceEpoch - requestedAtMs >
          const Duration(minutes: 10).inMilliseconds;

  RideRequest copyWith({int? proposedPrice}) => RideRequest(
    id: id,
    riderInitials: riderInitials,
    riderName: riderName,
    pickup: pickup,
    dropoff: dropoff,
    distanceKm: distanceKm,
    proposedPrice: proposedPrice ?? this.proposedPrice,
    pickupLat: pickupLat,
    pickupLng: pickupLng,
    dropLat: dropLat,
    dropLng: dropLng,
    rideType: rideType,
    paymentMethod: paymentMethod,
    requestedAtMs: requestedAtMs,
    preferredDriverGender: preferredDriverGender,
  );
}
