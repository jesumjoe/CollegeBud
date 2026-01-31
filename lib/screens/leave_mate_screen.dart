import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../models/subject_stats.dart';
import '../widgets/animated_list_item.dart';

class LeaveMateScreen extends StatefulWidget {
  const LeaveMateScreen({super.key});

  @override
  State<LeaveMateScreen> createState() => _LeaveMateScreenState();
}

class _LeaveMateScreenState extends State<LeaveMateScreen> {
  int _currentStep = 0;
  SubjectStats? _selectedSubject;
  int _leaveHours = 1;
  double _targetPercentage = 75.0;

  void _reset() {
    setState(() {
      _currentStep = 0;
      _selectedSubject = null;
      _leaveHours = 1;
      _targetPercentage = 75.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("LeaveMate",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildCurrentStep(context, isDark),
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context, bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildSubjectSelection(context, isDark);
      case 1:
        return _buildHoursInput(context, isDark);
      case 2:
        return _buildAnalysis(context, isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1: SUBJECT SELECTION (Vertical List)
  Widget _buildSubjectSelection(BuildContext context, bool isDark) {
    final provider = context.watch<AttendanceProvider>();
    final subjects = provider.subjects;

    if (subjects.isEmpty) {
      return Center(
          child: Text("No subjects found",
              style: TextStyle(color: isDark ? Colors.white : Colors.black)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        key: const ValueKey(0),
        children: [
          Text(
            "Select a Subject",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black),
          ),
          const SizedBox(height: 32),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subjects.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final subject = subjects[index];
              final isSafe = subject.truePercentage >= 75.0;

              return AnimatedListItem(
                index: index,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSubject = subject;
                      _currentStep = 1;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isDark
                              ? Colors.white12
                              : const Color(0xFFE0E0E0)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isSafe
                              ? (isDark
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.green.shade50)
                              : (isDark
                                  ? Colors.red.withOpacity(0.2)
                                  : Colors.red.shade50),
                          child: Icon(
                            isSafe ? Icons.check : Icons.priority_high,
                            color: isSafe ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subject.name,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color:
                                        isDark ? Colors.white : Colors.black87),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${subject.truePercentage.toStringAsFixed(1)}%",
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: isSafe
                                  ? (isDark
                                      ? Colors.greenAccent
                                      : Colors.green.shade700)
                                  : (isDark
                                      ? Colors.redAccent
                                      : Colors.red.shade700)),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // STEP 2: HOURS INPUT (Arrows)
  Widget _buildHoursInput(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        key: const ValueKey(1),
        children: [
          Text(
            "Hours to Leave",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedSubject?.name ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16, color: isDark ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(height: 48),

          // Custom Input
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 48),
                color: isDark ? Colors.white : Colors.black,
                onPressed: () {
                  setState(() => _leaveHours++);
                },
              ),
              const SizedBox(height: 16),
              Text(
                "$_leaveHours",
                style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 16),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 48),
                color: isDark ? Colors.white : Colors.black,
                onPressed: () {
                  if (_leaveHours > 1) setState(() => _leaveHours--);
                },
              ),
            ],
          ),

          const SizedBox(height: 64),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _currentStep = 2);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? const Color(0xFFFFD54F) : const Color(0xFF2D3436),
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text("ANALYZE",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }

  // STEP 3: ANALYSIS (Concise)
  Widget _buildAnalysis(BuildContext context, bool isDark) {
    if (_selectedSubject == null) return const SizedBox.shrink();

    final int present = _selectedSubject!.totalHours -
        (_selectedSubject!.blueAbsents - _selectedSubject!.greenDutyLeaves)
            .clamp(0, _selectedSubject!.totalHours);
    final int total = _selectedSubject!.totalHours;

    // Impact Logic
    final int newTotal = total + _leaveHours;
    final double projectedPct = (present / newTotal) * 100;
    final bool isSafe = projectedPct >= _targetPercentage;

    // Overall Impact Logic
    final provider = context.read<AttendanceProvider>();
    double currentOverallPct = provider.overallPercentage;

    // Calculate new overall
    int allTotal = 0;
    int allPresent = 0;
    for (var s in provider.subjects) {
      allTotal += s.totalHours;
      int realAbsents =
          (s.blueAbsents - s.greenDutyLeaves).clamp(0, s.totalHours);
      allPresent += (s.totalHours - realAbsents);
    }

    final int newAllTotal = allTotal + _leaveHours;
    final double projectedOverallPct = (allPresent / newAllTotal) * 100;

    // Chips Options
    final List<double> targets = [75.0, 80.0, 85.0, 90.0, 95.0];

    // Advice Logic
    int daysAvailableToLeave = 0;
    int attendanceNeeded = 0;

    if ((present / total) * 100 >= _targetPercentage) {
      daysAvailableToLeave =
          ((100 * present - _targetPercentage * total) / _targetPercentage)
              .floor();
    } else {
      attendanceNeeded = ((_targetPercentage * total - 100 * present) /
              (100 - _targetPercentage))
          .ceil();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      key: const ValueKey(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Status
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: isSafe
                  ? (isDark
                      ? Colors.green.withOpacity(0.2)
                      : const Color(0xFFA5D6A7).withOpacity(0.3))
                  : (isDark
                      ? Colors.red.withOpacity(0.2)
                      : const Color(0xFFFF8A80).withOpacity(0.3)),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: isSafe
                      ? (isDark ? Colors.greenAccent : Colors.green)
                      : (isDark ? Colors.redAccent : Colors.red),
                  width: 2),
            ),
            child: Column(
              children: [
                Icon(
                  isSafe
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                  size: 48,
                  color: isSafe
                      ? (isDark ? Colors.greenAccent : Colors.green[800])
                      : (isDark ? Colors.redAccent : Colors.red[900]),
                ),
                const SizedBox(height: 12),
                Text(
                  isSafe ? "Safe to Take Leave!" : "Don't Take Leave!",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: isDark ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  "Will drop to ${projectedPct.toStringAsFixed(2)}%",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black54),
                ),
                const SizedBox(height: 8),
                Text(
                  "Overall: ${currentOverallPct.toStringAsFixed(2)}% ➝ ${projectedOverallPct.toStringAsFixed(2)}%",
                  style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : Colors.black45),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Percentage Toggles
          Center(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: targets.map((pct) {
                final isSelected = _targetPercentage == pct;
                return ChoiceChip(
                  label: Text("${pct.toInt()}%"),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _targetPercentage = pct);
                  },
                  selectedColor: isDark
                      ? const Color(0xFFFFD54F)
                      : const Color(0xFF2D3436),
                  backgroundColor:
                      isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                  labelStyle: TextStyle(
                      color: isSelected
                          ? (isDark ? Colors.black : Colors.white)
                          : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide.none),
                  showCheckmark: false,
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 32),

          // Detailed Advice Card (Concise)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: isDark ? Colors.white12 : Colors.black12),
            ),
            child: Column(
              children: [
                Text("TO MAINTAIN ${_targetPercentage.toInt()}%",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: isDark ? Colors.white54 : Colors.grey)),
                const SizedBox(height: 16),
                if (daysAvailableToLeave > 0) ...[
                  Text(
                    "You can take",
                    style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white70 : Colors.black54),
                  ),
                  Text(
                    "$daysAvailableToLeave",
                    style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                        color: isDark ? Colors.greenAccent : Colors.green[700]),
                  ),
                  Text(
                    "more class(es)",
                    style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white70 : Colors.black54),
                  ),
                ] else if (attendanceNeeded > 0) ...[
                  Text(
                    "You need to attend",
                    style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white70 : Colors.black54),
                  ),
                  Text(
                    "$attendanceNeeded",
                    style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                        color: isDark ? Colors.redAccent : Colors.red[700]),
                  ),
                  Text(
                    "more class(es)",
                    style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white70 : Colors.black54),
                  ),
                ] else
                  Text(
                    "Can't Take Leave Anymore!",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          OutlinedButton(
            onPressed: _reset,
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white : Colors.black,
              side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text("CHECK ANOTHER SUBJECT"),
          )
        ],
      ),
    );
  }
}
