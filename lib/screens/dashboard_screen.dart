import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:attcalci/providers/attendance_provider.dart';
import 'package:attcalci/widgets/subject_card.dart';
import 'package:attcalci/widgets/animated_list_item.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: provider.isLoading && provider.subjects.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => context.read<AttendanceProvider>().refreshData(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        // Lavender / Dark Navy Background Blob
                        Container(
                          height: 250,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1A237E)
                                : const Color(
                                    0xFFDEDCFF), // Indigo 900 vs Lavender
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(40),
                              bottomRight: Radius.circular(40),
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            // AppBar
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 50, 20, 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Hello,",
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black54)),
                                      Text(provider.studentName,
                                          style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black)),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      // Refresh Button (Context specific)
                                      IconButton(
                                        icon: Icon(Icons.refresh,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black54),
                                        onPressed: () => context
                                            .read<AttendanceProvider>()
                                            .refreshData(),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),

                            // Overall Card overlaying the background
                            if (provider.subjects.isNotEmpty)
                              _buildOverallCard(
                                  context,
                                  provider.overallPercentage,
                                  provider.officialOverallPercentage,
                                  isDark),
                          ],
                        )
                      ],
                    ),
                  ),

                  // List Title
                  if (provider.subjects.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                        child: Text("My Subjects",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black)),
                      ),
                    ),

                  // Subject List
                  if (provider.subjects.isNotEmpty)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => AnimatedListItem(
                            index: index,
                            child:
                                SubjectCard(stats: provider.subjects[index])),
                        childCount: provider.subjects.length,
                      ),
                    )
                  else
                    SliverFillRemaining(
                      child: Center(
                        child: provider.error != null
                            ? Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(provider.error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.red)),
                              )
                            : Text('No Data Found',
                                style: TextStyle(
                                    color:
                                        isDark ? Colors.white : Colors.black)),
                      ),
                    )
                ],
              ),
            ),
    );
  }

  Widget _buildOverallCard(BuildContext context, double percentage,
      double officialPercentage, bool isDark) {
    // Light: Pastel Yellow (FFD54F) | Dark: Muted Gold (FBC02D)
    final Color cardColor =
        isDark ? const Color(0xFFFBC02D) : const Color(0xFFFFD54F);
    final Color textColor = Colors.black; // Text on yellow is always black

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: isDark ? Colors.white24 : Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Overall Attendance",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${percentage.toStringAsFixed(1)}%",
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        color: textColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Text(
                  percentage < 75 ? "Direct Risk ⚠️" : "Safe Zone ✅",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.black),
                ),
              ),
              const SizedBox(height: 8),
              if ((percentage - officialPercentage).abs() > 0.1)
                Text(
                  "Original: ${officialPercentage.toStringAsFixed(1)}%",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textColor.withOpacity(0.7)),
                ),
            ],
          ),

          // Ring Chart
          SizedBox(
            height: 80,
            width: 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 1,
                  color: Colors.white.withOpacity(0.5),
                  strokeWidth: 12,
                ),
                CircularProgressIndicator(
                  value: percentage / 100,
                  color: Colors.black,
                  strokeWidth: 12,
                  strokeCap: StrokeCap.round,
                ),
                Center(
                    child: Icon(
                        percentage < 75
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline,
                        size: 32,
                        color: Colors.black))
              ],
            ),
          )
        ],
      ),
    );
  }
}
