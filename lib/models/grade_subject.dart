class GradeSubject {
  String id;
  String name;
  bool isPractical; // false = Theory Only, true = Theory + Practical

  // Marks (All optional to allow saving incomplete states, but UI will enforce required ones)
  double cia1;
  double cia2;
  double? cia3; // Optional
  double? practical; // Only for isPractical = true
  double attendance; // Default 5 if not entered

  double targetPercent;

  GradeSubject({
    required this.id,
    required this.name,
    required this.isPractical,
    required this.cia1,
    required this.cia2,
    this.cia3,
    this.practical,
    this.attendance = 5.0,
    required this.targetPercent,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isPractical': isPractical,
      'cia1': cia1,
      'cia2': cia2,
      'cia3': cia3,
      'practical': practical,
      'attendance': attendance,
      'targetPercent': targetPercent,
    };
  }

  factory GradeSubject.fromJson(Map<String, dynamic> json) {
    return GradeSubject(
      id: json['id'],
      name: json['name'],
      isPractical: json['isPractical'],
      cia1: json['cia1'],
      cia2: json['cia2'],
      cia3: json['cia3'],
      practical: json['practical'],
      attendance: json['attendance'] ?? 5.0,
      targetPercent: json['targetPercent'],
    );
  }
}
