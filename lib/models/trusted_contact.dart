class TrustedContact {
  final String initial;
  final String name;
  final String relation;
  bool autoShare;

  TrustedContact({
    required this.initial,
    required this.name,
    required this.relation,
    this.autoShare = true,
  });
}
