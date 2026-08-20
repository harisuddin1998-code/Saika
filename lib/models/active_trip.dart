import 'package:flutter/foundation.dart';
import 'driver_offer.dart';
import 'ride_request.dart';

class ActiveTrip {
  final DriverOffer driver;
  final RideRequest request;
  final bool arrived;

  const ActiveTrip({
    required this.driver,
    required this.request,
    this.arrived = false,
  });

  ActiveTrip copyWith({bool? arrived}) => ActiveTrip(
    driver: driver,
    request: request,
    arrived: arrived ?? this.arrived,
  );
}

/// Tracks the rider's currently-in-progress trip so the Home screen's
/// "Ongoing Trip" tab can show it without threading driver/request state
/// through the navigation stack.
class ActiveTripStore {
  ActiveTripStore._();
  static final ActiveTripStore instance = ActiveTripStore._();

  final ValueNotifier<ActiveTrip?> current = ValueNotifier(null);

  void start(DriverOffer driver, RideRequest request) {
    current.value = ActiveTrip(driver: driver, request: request);
  }

  void markArrived() {
    final trip = current.value;
    if (trip != null) current.value = trip.copyWith(arrived: true);
  }

  void end() {
    current.value = null;
  }
}
