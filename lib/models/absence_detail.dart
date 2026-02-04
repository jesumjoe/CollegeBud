class AbsenceDetail {
  final DateTime date;
  final String subjectName;
  final String subjectCode;
  final int period;
  final bool isDutyLeave;

  AbsenceDetail({
    required this.date,
    required this.subjectName,
    required this.subjectCode,
    required this.period,
    required this.isDutyLeave,
  });
}
