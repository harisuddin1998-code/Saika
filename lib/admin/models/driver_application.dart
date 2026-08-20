class DriverApplication {
  final String name;
  final String vehicle;
  final String submittedAgo;
  final bool cnicVerified;
  final bool policeCertVerified;

  const DriverApplication({
    required this.name,
    required this.vehicle,
    required this.submittedAgo,
    required this.cnicVerified,
    required this.policeCertVerified,
  });
}
