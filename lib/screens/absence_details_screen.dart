import 'package:attcalci/models/absence_detail.dart';
import 'package:attcalci/providers/attendance_provider.dart';
import 'package:attcalci/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AbsenceDetailsScreen extends StatelessWidget {
  const AbsenceDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AttendanceProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final absenceMap = provider.absencesByDate;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Absence Details"),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: absenceMap.isEmpty
          ? Center(
              child: Text(
                "No absences recorded! 🎉",
                style: TextStyle(
                  fontSize: 18,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  color: isDark ? Colors.black26 : Colors.grey[200],
                  width: double.infinity,
                  child: const Center(
                    child: Text(
                      "Periods marked in Green are Co-curricular Leave",
                      style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: absenceMap.length,
                    separatorBuilder: (ctx, i) => const Divider(),
                    itemBuilder: (context, index) {
                      final date = absenceMap.keys.elementAt(index);
                      final details = absenceMap[date]!;
                      final dateStr = DateFormat('dd-MM-yyyy').format(date);
                      final dayStr = DateFormat('EEEE').format(date);

                      final totalMissed = details.length;
                      final dutyLeaves =
                          details.where((d) => d.isDutyLeave).length;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        tileColor:
                            isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        title: Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        leading: CircleAvatar(
                          backgroundColor:
                              isDark ? Colors.red[900] : Colors.red[100],
                          child: Text("$totalMissed",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDark ? Colors.white : Colors.red[900])),
                        ),
                        subtitle: Text(
                          dayStr,
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        trailing: CircleAvatar(
                          radius: 14,
                          backgroundColor: dutyLeaves > 0
                              ? (isDark ? Colors.green[900] : Colors.green[100])
                              : (isDark ? Colors.grey[800] : Colors.grey[200]),
                          child: Text(
                            "$dutyLeaves",
                            style: TextStyle(
                              color: dutyLeaves > 0
                                  ? (isDark ? Colors.white : Colors.green[900])
                                  : (isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[500]),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onTap: () => _showDetailsDialog(
                            context, dateStr, details, isDark),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _showDetailsDialog(BuildContext context, String dateStr,
      List<AbsenceDetail> details, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          dateStr,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: details.length,
            itemBuilder: (ctx, i) {
              final d = details[i];

              // Repo: int period = p - 1; (where p starts at 2). So p=2 -> period=1 (1st hour).
              // Wait, if p=2 is Col 2. Col 0=Date, Col 1=Day. Col 2=1st Hour.
              // So p-1 = 1.
              // If we want "Period 1", we should use period.
              // Let's verify repo logic.
              // Repo Step 230: int period = p - 1;
              // If p=2 (1st hour col), period=1.
              // If I want to show "Period 1", strictly speaking it is `period`.
              // But if the loop starts p=2...
              // Let's check logic:
              // Index 0: 14-11-2025
              // Index 1: Friday
              // Index 2: Period 1 Data.
              // p=2. period = p-1 = 1.
              // So `period` value 1 means "Period 1"? Or is it using 1-based indexing?
              // `LastAbsenceInfo` uses this logic: `1st Hour`.
              // Code uses `p` directly as column index.
              // Usually display is "Period <period>". if period is 1, it matches 1st Hour.

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: d.isDutyLeave
                      ? (isDark
                          ? Colors.green[900]!.withOpacity(0.5)
                          : const Color(
                              0xFF00C800)) // Bright Green for Light Mode as per screenshot
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  // Border for non-OD?
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Period ${d.period + 1}", // Adjust formatted string
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: d.isDutyLeave
                            ? Colors.black
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        d.subjectCode,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: d.isDutyLeave
                              ? Colors.black
                              : (isDark ? Colors.white54 : Colors.grey[700]),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }
}
