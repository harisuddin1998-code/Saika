enum SosStatus { active, resolved }

class SosAlert {
  final String id;
  final String riderName;
  final String driverName;
  final String area;
  final String triggeredAgo;
  final SosStatus status;

  const SosAlert({
    required this.id,
    required this.riderName,
    required this.driverName,
    required this.area,
    required this.triggeredAgo,
    required this.status,
  });

  SosAlert copyWith({SosStatus? status}) => SosAlert(
        id: id,
        riderName: riderName,
        driverName: driverName,
        area: area,
        triggeredAgo: triggeredAgo,
        status: status ?? this.status,
      );
}
