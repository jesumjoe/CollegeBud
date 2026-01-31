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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Color Logic
    final bool isSafe = truePct >= 75.0;
    final Color statusColor =
        isSafe ? const Color(0xFFA5D6A7) : const Color(0xFFFF8A80);
    final Color accentColor =
        isSafe ? Colors.green.shade700 : Colors.red.shade700;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFF0F0F0),
            width: 1.5),
        boxShadow: [
          BoxShadow(
              color: isDark ? Colors.black26 : const Color(0x08000000),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Name and Status Icon
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isSafe ? Icons.check_circle : Icons.warning_rounded,
                        color: accentColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stats.name,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF2D3436)),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4)),
                            child: Text(stats.code,
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${truePct.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: accentColor,
                          ),
                        ),
                        Text("Attendance",
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey.shade500)),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: truePct / 100,
                    backgroundColor:
                        isDark ? Colors.grey.shade800 : const Color(0xFFF5F5F5),
                    color: accentColor,
                    minHeight: 8,
                  ),
                ),

                const SizedBox(height: 16),

                // Footer: Attended
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.class_, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          "Attended: $attendedHours / ${stats.totalHours}",
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Colors.black54),
                        ),
                      ],
                    ),
                    Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 20,
                        color: Colors.grey),
                  ],
                ),

                if (_isExpanded) ...[
                  const Divider(height: 32),

                  // Sub-text stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Official: ${officialPct.toStringAsFixed(1)}%',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12),
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
                      _buildStatItem('Total', stats.totalHours.toString(),
                          isDark: isDark),
                      _buildStatItem('Absent', realAbsents.toString(),
                          color: const Color(0xFFFF8A80), isDark: isDark),
                      _buildStatItem(
                          'Duty Leave', stats.greenDutyLeaves.toString(),
                          color: const Color(0xFFA5D6A7), isDark: isDark),
                    ],
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value,
      {Color? color, required bool isDark}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color?.withOpacity(0.2) ??
                (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color?.withOpacity(1.0) ??
                      (isDark ? Colors.white : Colors.black87))),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
