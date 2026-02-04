class SubjectStats {
  final String code;
  final String name; // Added name for UI
  int totalHours;
  int blueAbsents;
  int greenDutyLeaves;

  SubjectStats({
    required this.code,
    required this.name,
    this.totalHours = 0,
    this.blueAbsents = 0,
    this.greenDutyLeaves = 0,
  });

  // Official: Matches Website (Treats Duty Leave as Absent)
  // 'blueAbsents' contains the Total Absent count from Summary (which includes Duty Leaves)
  double get officialPercentage {
    if (totalHours == 0) return 0.0;
    final int present = totalHours - blueAbsents;
    return (present / totalHours) * 100;
  }

  // True: Treats Duty Leave as Present
  // Real Absent = Official Absent - Duty Leaves
  double get truePercentage {
    if (totalHours == 0) return 0.0;
    int realAbsents = blueAbsents - greenDutyLeaves;
    if (realAbsents < 0) realAbsents = 0;

    final int present = totalHours - realAbsents;
    return (present / totalHours) * 100;
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'totalHours': totalHours,
      'blueAbsents': blueAbsents,
      'greenDutyLeaves': greenDutyLeaves,
    };
  }

  factory SubjectStats.fromJson(Map<String, dynamic> json) {
    return SubjectStats(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      totalHours: json['totalHours'] ?? 0,
      blueAbsents: json['blueAbsents'] ?? 0,
      greenDutyLeaves: json['greenDutyLeaves'] ?? 0,
    );
  }
}
