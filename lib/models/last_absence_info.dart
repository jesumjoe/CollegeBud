class LastAbsenceInfo {
  final DateTime date;
  final String subjectName;
  final int period;
  final double impact; // % drop caused by this bunk (approx)

  LastAbsenceInfo({
    required this.date,
    required this.subjectName,
    required this.period,
    required this.impact,
  });
}
