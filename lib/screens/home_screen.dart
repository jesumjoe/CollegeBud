import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:attcalci/providers/attendance_provider.dart';
import 'package:attcalci/providers/theme_provider.dart';
import 'package:attcalci/models/last_absence_info.dart';
import 'package:attcalci/screens/dashboard_screen.dart';
import 'package:attcalci/screens/leave_mate_screen.dart';
import 'package:attcalci/screens/grade_dashboard_screen.dart';
import 'package:attcalci/screens/absence_details_screen.dart';
import 'package:attcalci/screens/time_table_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Header
          Container(
            height: 350,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A237E) : const Color(0xFFDEDCFF),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50),
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Theme Toggle (Top Right)
                              Align(
                                alignment: Alignment.topRight,
                                child: IconButton(
                                  icon: Icon(
                                      isDark
                                          ? Icons.light_mode
                                          : Icons.dark_mode,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black54),
                                  onPressed: () =>
                                      themeProvider.toggleTheme(!isDark),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Column(
                                children: [
                                  Text("Welcome,",
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black54)),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                          context: context,
                                          builder: (context) {
                                            final controller =
                                                TextEditingController(
                                                    text: provider
                                                                .studentName ==
                                                            "Student"
                                                        ? ""
                                                        : provider.studentName);
                                            return AlertDialog(
                                              title: const Text("Edit Name"),
                                              content: TextField(
                                                controller: controller,
                                                decoration:
                                                    const InputDecoration(
                                                        hintText:
                                                            "Enter your name"),
                                                textCapitalization:
                                                    TextCapitalization.words,
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text("Cancel"),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    if (controller.text
                                                        .trim()
                                                        .isNotEmpty) {
                                                      provider.updateName(
                                                          controller.text
                                                              .trim());
                                                    }
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text("Save"),
                                                ),
                                              ],
                                            );
                                          });
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(provider.studentName,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black)),
                                        const SizedBox(width: 8),
                                        Icon(Icons.edit,
                                            size: 16,
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.black45),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 40),

                          // Menu Cards
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (provider.isLoggedIn)
                                _buildLastBunkTile(
                                    context, provider.lastAbsenceInfo, isDark),
                              if (provider.isLoggedIn)
                                const SizedBox(height: 24),
                              _buildMenuButton(
                                context,
                                title: "Check Attendance",
                                subtitle: "View your subjects and stats",
                                icon: Icons.assignment_ind_rounded,
                                color: isDark
                                    ? const Color(0xFFFBC02D)
                                    : const Color(0xFFFFD54F), // Yellow
                                onTap: () => Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation,
                                              secondaryAnimation) =>
                                          const DashboardScreen(),
                                      transitionsBuilder: (context, animation,
                                          secondaryAnimation, child) {
                                        return FadeTransition(
                                            opacity: animation, child: child);
                                      },
                                    )),
                                isDark: isDark,
                              ),
                              const SizedBox(height: 24),
                              _buildMenuButton(
                                context,
                                title: "Absence Details",
                                subtitle: "View history & duty leaves",
                                icon: Icons.history_rounded,
                                color: isDark
                                    ? const Color(0xFFEF5350)
                                    : const Color(0xFFEF9A9A), // Red
                                onTap: () => Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation,
                                              secondaryAnimation) =>
                                          const AbsenceDetailsScreen(),
                                      transitionsBuilder: (context, animation,
                                          secondaryAnimation, child) {
                                        return FadeTransition(
                                            opacity: animation, child: child);
                                      },
                                    )),
                                isDark: isDark,
                              ),
                              const SizedBox(height: 24),
                              _buildMenuButton(
                                context,
                                title: "LeaveMate",
                                subtitle: "Calculate if you can leave",
                                icon: Icons.calculate_rounded,
                                color: isDark
                                    ? const Color(0xFF66BB6A)
                                    : const Color(0xFFA5D6A7), // Green
                                onTap: () => Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation,
                                              secondaryAnimation) =>
                                          const LeaveMateScreen(),
                                      transitionsBuilder: (context, animation,
                                          secondaryAnimation, child) {
                                        const begin = Offset(0.0, 1.0);
                                        const end = Offset.zero;
                                        const curve = Curves.ease;
                                        var tween = Tween(
                                                begin: begin, end: end)
                                            .chain(CurveTween(curve: curve));
                                        return SlideTransition(
                                            position: animation.drive(tween),
                                            child: child);
                                      },
                                    )),
                                isDark: isDark,
                              ),
                              const SizedBox(height: 24),
                              _buildMenuButton(
                                context,
                                title: "Time Table",
                                subtitle: "View your weekly schedule",
                                icon: Icons.calendar_month_rounded,
                                color: isDark
                                    ? const Color(0xFFAB47BC)
                                    : const Color(0xFFBA68C8), // Purple
                                onTap: () => Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation,
                                              secondaryAnimation) =>
                                          const TimeTableScreen(),
                                      transitionsBuilder: (context, animation,
                                          secondaryAnimation, child) {
                                        return FadeTransition(
                                            opacity: animation, child: child);
                                      },
                                    )),
                                isDark: isDark,
                              ),
                              const SizedBox(height: 24),
                              _buildMenuButton(
                                context,
                                title: "Grade Companion",
                                subtitle: "Predict scores & difficulty",
                                icon: Icons.school_rounded,
                                color: isDark
                                    ? const Color(0xFF42A5F5)
                                    : const Color(0xFF90CAF9), // Blue
                                onTap: () => Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation,
                                              secondaryAnimation) =>
                                          const GradeDashboardScreen(),
                                      transitionsBuilder: (context, animation,
                                          secondaryAnimation, child) {
                                        const begin = Offset(
                                            1.0, 0.0); // Slide from right
                                        const end = Offset.zero;
                                        const curve = Curves.ease;
                                        var tween = Tween(
                                                begin: begin, end: end)
                                            .chain(CurveTween(curve: curve));
                                        return SlideTransition(
                                            position: animation.drive(tween),
                                            child: child);
                                      },
                                    )),
                                isDark: isDark,
                              ),
                            ],
                          ),

                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: 24.0, top: 40),
                            child: TextButton.icon(
                              onPressed: () =>
                                  context.read<AttendanceProvider>().logout(),
                              icon:
                                  const Icon(Icons.logout, color: Colors.grey),
                              label: const Text("Logout",
                                  style: TextStyle(color: Colors.grey)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: isDark ? Colors.white24 : Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Icon(icon, size: 32, color: Colors.black87),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black54)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: Colors.black54, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLastBunkTile(
      BuildContext context, LastAbsenceInfo? info, bool isDark) {
    String text;
    String subtext = "";
    Color color;
    IconData icon;

    if (info == null) {
      text = "No recent bunks! 🎉";
      color =
          isDark ? const Color(0xFF66BB6A) : const Color(0xFFA5D6A7); // Green
      icon = Icons.sentiment_very_satisfied;
    } else {
      final now = DateTime.now();
      final diff = now.difference(info.date).inDays;
      String timeStr;

      if (diff == 0) {
        timeStr = "Today";
      } else if (diff == 1) {
        timeStr = "Yesterday";
      } else {
        timeStr = "$diff days ago";
      }

      // Format Period (e.g., 0 -> 1st Hour)
      // Assuming 0 is 1st Hour, logic p-1 in repo
      String periodStr = "${info.period + 1}th Hour";
      if (info.period == 0) periodStr = "1st Hour";
      if (info.period == 1) periodStr = "2nd Hour";
      if (info.period == 2) periodStr = "3rd Hour";

      text = "Last bunk: $timeStr 😬";

      // Subtext: Subject Name + Impact
      // E.g. "Software Engg (3rd Hour) • -1.2%"
      subtext =
          "${info.subjectName} ($periodStr)\nRisk: -${info.impact.toStringAsFixed(1)}%";

      color = isDark ? const Color(0xFFEF5350) : const Color(0xFFEF9A9A); // Red
      icon = Icons.warning_amber_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: isDark ? Colors.white24 : Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.black87, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (subtext.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      subtext,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                          height: 1.2),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
