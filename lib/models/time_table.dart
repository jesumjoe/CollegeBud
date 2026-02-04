class TimeTableDay {
  final String dayName;
  final List<String>
      periods; // List of subject names for each period (P1, P2, ...)

  TimeTableDay({
    required this.dayName,
    required this.periods,
  });

  Map<String, dynamic> toJson() {
    return {
      'dayName': dayName,
      'periods': periods,
    };
  }

  factory TimeTableDay.fromJson(Map<String, dynamic> json) {
    return TimeTableDay(
      dayName: json['dayName'] ?? '',
      periods:
          (json['periods'] as List<dynamic>?)?.cast<String>().toList() ?? [],
    );
  }
}
