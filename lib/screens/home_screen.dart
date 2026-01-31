import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:attcalci/providers/attendance_provider.dart';
import 'package:attcalci/providers/theme_provider.dart';
import 'package:attcalci/screens/dashboard_screen.dart';
import 'package:attcalci/screens/leave_mate_screen.dart';
import 'package:attcalci/screens/grade_dashboard_screen.dart';

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
}
