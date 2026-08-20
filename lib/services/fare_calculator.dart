import '../models/ride_request.dart';

/// Simple transparent fare calculator for the demo: anchors the per-km rate
/// to what it costs to run the EV, then splits every fare into fuel
/// (electricity), maintenance, and the driver's own profit — so the price
/// shown to the rider always traces back to a real cost breakdown instead
/// of a flat guess, and changes whenever distance or ride type changes.
class FareCalculator {
  /// Rough cost (Rs) to fully charge the car.
  static const double chargeCostRs = 200;

  /// Range (km) the car gets from one full charge.
  static const double chargeRangeKm = 20;

  static const double fuelShare = 0.20;
  static const double maintenanceShare = 0.30;
  static const double profitShare = 0.50;

  /// Rs per km once fuel cost is scaled up to the full fare (fuel is 20% of
  /// the fare, so fare/km = fuel-cost/km ÷ 0.20).
  static double get farePerKm => (chargeCostRs / chargeRangeKm) / fuelShare;

  static double _multiplierFor(RideType type) => switch (type) {
    RideType.solo => 1.0,
    RideType.couple => 1.15,
    RideType.family => 1.4,
  };

  /// Total fare for a ride, rounded to the nearest Rs 10 so it never lands
  /// on an odd number.
  static int fareFor(double distanceKm, RideType type) {
    final safeDistance = distanceKm <= 0 ? 1.0 : distanceKm;
    final raw = farePerKm * safeDistance * _multiplierFor(type);
    final rounded = (raw / 10).round() * 10;
    return rounded < 50 ? 50 : rounded;
  }

  /// Cost floor — fuel + maintenance only, so a rider can negotiate the
  /// price down but never below what it actually costs to run the trip.
  static int minFareFor(double distanceKm, RideType type) {
    final total = fareFor(distanceKm, type);
    return ((total * (fuelShare + maintenanceShare)) / 10).round() * 10;
  }

  static FareBreakdown breakdownFor(double distanceKm, RideType type) {
    final total = fareFor(distanceKm, type);
    return FareBreakdown(
      fuel: (total * fuelShare).round(),
      maintenance: (total * maintenanceShare).round(),
      profit: (total * profitShare).round(),
      total: total,
    );
  }
}

class FareBreakdown {
  final int fuel;
  final int maintenance;
  final int profit;
  final int total;
  const FareBreakdown({
    required this.fuel,
    required this.maintenance,
    required this.profit,
    required this.total,
  });
}
