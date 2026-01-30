import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../widgets/subject_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => context.read<AttendanceProvider>().refreshData(),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => context.read<AttendanceProvider>().logout(),
          )
        ],
      ),
      body: provider.isLoading && provider.subjects.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => context.read<AttendanceProvider>().refreshData(),
              child: provider.subjects.isEmpty
                  ? Center(
                      child: provider.error != null
                          ? Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(provider.error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.red)),
                            )
                          : const Text('No Data Found'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: provider.subjects.length + 1, // +1 for Header
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // Header Section
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                child: Text(
                                  "Hey, ${provider.studentName}",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                              _buildOverallCard(
                                  context, provider.overallPercentage),
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Text("Subject Wise",
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          );
                        }
                        return SubjectCard(stats: provider.subjects[index - 1]);
                      },
                    ),
            ),
    );
  }

  Widget _buildOverallCard(BuildContext context, double percentage) {
    final Color color = percentage < 75.0 ? Colors.red : Colors.green;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 6,
      color: Theme.of(context).colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Overall Attendance",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${percentage.toStringAsFixed(1)}%",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color, width: 2),
                    ),
                    child: Text(
                      percentage < 75 ? "Direct Risk" : "Safe",
                      style: TextStyle(
                          color: color.computeLuminance() > 0.5
                              ? color
                              : Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
            SizedBox(
              height: 80,
              width: 80,
              child: CircularProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.white24,
                color: color,
                strokeWidth: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
