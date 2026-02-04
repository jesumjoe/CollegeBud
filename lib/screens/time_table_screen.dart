import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../models/time_table.dart';
import '../models/subject_stats.dart';

class TimeTableScreen extends StatefulWidget {
  const TimeTableScreen({super.key});

  @override
  State<TimeTableScreen> createState() => _TimeTableScreenState();
}

class _TimeTableScreenState extends State<TimeTableScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch time table if empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AttendanceProvider>();
      if (provider.timeTable.isEmpty) {
        provider.fetchTimeTable();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeTable = provider.timeTable;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Time Table"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.fetchTimeTable(),
          )
        ],
      ),
      body: timeTable.isEmpty
          ? Center(
              child: provider.isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("No Time Table Found",
                            style: TextStyle(color: Colors.grey, fontSize: 18)),
                        TextButton(
                            onPressed: () => provider.fetchTimeTable(),
                            child: Text("Retry"))
                      ],
                    ),
            )
          : DefaultTabController(
              length: timeTable.length,
              child: Column(
                children: [
                  Container(
                    color: isDark ? Colors.black12 : Colors.grey.shade100,
                    child: TabBar(
                      isScrollable: true,
                      labelColor: isDark ? Colors.white : Colors.black,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: isDark
                          ? const Color(0xFFAB47BC)
                          : const Color(0xFFBA68C8),
                      tabs: timeTable
                          .map((day) => Tab(text: day.dayName))
                          .toList(),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: timeTable.map((day) {
                        return _buildDayView(day, provider, isDark);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDayView(
      TimeTableDay day, AttendanceProvider provider, bool isDark) {
    if (day.periods.isEmpty) {
      return Center(
          child: Text("No classes scheduled",
              style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: day.periods.length,
      itemBuilder: (context, index) {
        final subjectName = day.periods[index];
        final periodNumber = index + 1;

        // Find stats
        SubjectStats? stats;
        try {
          // Fuzzy match subject name to stats
          // This is tricky because Time Table names might differ slightly from Summary names
          // Simple approach: Contains match
          stats = provider.subjects.firstWhere((s) {
            final sName = s.name.toLowerCase().replaceAll(RegExp(r'\s+'), '');
            final tName =
                subjectName.toLowerCase().replaceAll(RegExp(r'\s+'), '');
            return sName.contains(tName) || tName.contains(sName);
          });
        } catch (_) {}

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Text(
                "$periodNumber",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
            title: Text(
              subjectName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            trailing: stats != null
                ? _buildPercentageBadge(stats.truePercentage)
                : null,
            subtitle: stats != null
                ? Text("Classes: ${stats.totalHours}",
                    style: TextStyle(fontSize: 12, color: Colors.grey))
                : null,
          ),
        );
      },
    );
  }

  Widget _buildPercentageBadge(double percentage) {
    Color color;
    if (percentage >= 85) {
      color = Colors.green;
    } else if (percentage >= 75) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        "${percentage.toStringAsFixed(1)}%",
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
