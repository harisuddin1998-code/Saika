class DriverOffer {
  final String driverId;
  final String initials;
  final String name;
  final String carModel;
  final String carColor;
  final String plate;
  final double rating;
  final int price;

  const DriverOffer({
    required this.driverId,
    required this.initials,
    required this.name,
    required this.carModel,
    required this.carColor,
    required this.plate,
    required this.rating,
    required this.price,
  });

  factory DriverOffer.fromJson(Map<String, dynamic> json) => DriverOffer(
        driverId: json['driverId'] as String? ?? '',
        initials: json['driverInitials'] as String? ?? '??',
        name: json['driverName'] as String? ?? 'Driver',
        carModel: json['carModel'] as String? ?? 'EV',
        carColor: json['carColor'] as String? ?? '',
        plate: json['plate'] as String? ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
        price: (json['price'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'driverId': driverId,
        'driverInitials': initials,
        'driverName': name,
        'carModel': carModel,
        'carColor': carColor,
        'plate': plate,
        'rating': rating,
        'price': price,
      };

  /// Stable key for deduping/matching offers from the same driver — a
  /// per-install ID rather than name/phone, so two drivers with the same
  /// name (or an unregistered test install) never collide.
  String get offerKey => driverId;
}
