import 'package:flutter/material.dart';
import '../models/subject_stats.dart';

class SubjectCard extends StatefulWidget {
  final SubjectStats stats;

  const SubjectCard({super.key, required this.stats});

  @override
  State<SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<SubjectCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;
    final double truePct = stats.truePercentage;
    final double officialPct = stats.officialPercentage;
    final double dutyLeaveImpact = truePct - officialPct;

    // Calculate effective attended hours (Total - Real Absent)
    final int realAbsents =
        (stats.blueAbsents - stats.greenDutyLeaves).clamp(0, stats.totalHours);
    final int attendedHours = stats.totalHours - realAbsents;

    // Color Logic: < 75 is Red, else Green
    final Color progressColor = truePct < 75.0 ? Colors.red : Colors.green;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Code and Name
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    stats.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(stats.code,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Main Progress Bar (True Attendance)
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: truePct / 100,
                      backgroundColor: Colors.grey.shade300,
                      color: progressColor,
                      minHeight: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${truePct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Basic Info (Always Visible): Attended / Total (Wait, user asked for total to be hidden?)
            // User said: "official, saved by, total, absent and duty leave should not be visible directly"
            // "Also add the actual number of class attended as well"
            // So Attended is likely the only thing visible besides Name/Percentage.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Attended: $attendedHours",
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      children: [
                        Text(_isExpanded ? "Hide Details" : "Show Details",
                            style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                        Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 16,
                            color: Colors.blue.shade700),
                      ],
                    ),
                  ),
                )
              ],
            ),

            if (_isExpanded) ...[
              const Divider(height: 24),

              // Sub-text stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Official: ${officialPct.toStringAsFixed(1)}%',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  if (dutyLeaveImpact > 0.1)
                    Text(
                      'Saved by Duty Leave: +${dutyLeaveImpact.toStringAsFixed(1)}%',
                      style: TextStyle(
                          color: Colors.amber.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Stats Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Total', stats.totalHours.toString()),
                  _buildStatItem('Absent', realAbsents.toString(),
                      color: Colors.red),
                  _buildStatItem('Duty Leave', stats.greenDutyLeaves.toString(),
                      color: Colors.teal),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
