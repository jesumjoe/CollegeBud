import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:attcalci/models/grade_subject.dart';
import 'package:attcalci/services/grade_storage_service.dart';
import 'package:attcalci/utils/grade_calculator.dart';
import 'package:attcalci/providers/attendance_provider.dart';
import 'package:uuid/uuid.dart';

class GradeEntryScreen extends StatefulWidget {
  final GradeSubject? subject;
  const GradeEntryScreen({super.key, this.subject});

  @override
  State<GradeEntryScreen> createState() => _GradeEntryScreenState();
}

class _GradeEntryScreenState extends State<GradeEntryScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 7; // Increased for Attendance

  // Data
  String _subjectName = "";
  bool? _isPractical; // null initially
  double? _cia1;
  double? _cia2;
  double? _cia3;
  double? _practical;
  double _attendance = 5.0; // Assume 5 default
  double _targetPercent = 75.0;

  // Controllers
  final TextEditingController _customSubjectCtrl = TextEditingController();
  final TextEditingController _cia1Ctrl = TextEditingController();
  final TextEditingController _cia2Ctrl = TextEditingController();
  final TextEditingController _cia3Ctrl = TextEditingController();
  final TextEditingController _practicalCtrl = TextEditingController();
  final TextEditingController _attendanceCtrl = TextEditingController(); // New

  @override
  void initState() {
    super.initState();
    if (widget.subject != null) {
      // Pre-fill if editing
      _subjectName = widget.subject!.name;
      _isPractical = widget.subject!.isPractical;
      _cia1 = widget.subject!.cia1;
      _cia2 = widget.subject!.cia2;
      _cia3 = widget.subject!.cia3;
      _practical = widget.subject!.practical;
      _attendance = widget.subject!.attendance;
      _targetPercent = widget.subject!.targetPercent;

      _customSubjectCtrl.text = _subjectName;
      _cia1Ctrl.text = _cia1.toString();
      _cia2Ctrl.text = _cia2.toString();
      if (_cia3 != null) _cia3Ctrl.text = _cia3.toString();
      if (_practical != null) _practicalCtrl.text = _practical.toString();
      _attendanceCtrl.text = _attendance.toString(); // Pre-fill attendance
    } else {
      _attendanceCtrl.text = "5"; // Default
    }
  }

  void _nextPage() {
    if (_validateStep(_currentStep)) {
      if (_currentStep < _totalSteps - 1) {
        _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
        setState(() => _currentStep++);
      } else {
        _save();
      }
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  bool _validateStep(int step) {
    if (step == 0) return _subjectName.isNotEmpty;
    if (step == 1) return _isPractical != null;
    if (step == 2) {
      _cia1 = double.tryParse(_cia1Ctrl.text);
      if (_cia1 == null) return false;
      if (_cia1! > 20) {
        _showError("CIA 1 cannot be more than 20");
        return false;
      }
      return true;
    }
    if (step == 3) {
      _cia2 = double.tryParse(_cia2Ctrl.text);
      if (_cia2 == null) return false;
      if (_cia2! > 50) {
        _showError("CIA 2 cannot be more than 50");
        return false;
      }
      return true;
    }
    if (step == 4) {
      if (_cia3Ctrl.text.isNotEmpty) {
        _cia3 = double.tryParse(_cia3Ctrl.text);
        if (_cia3 != null && _cia3! > 20) {
          _showError("CIA 3 cannot be more than 20");
          return false;
        }
        return _cia3 != null;
      }
      return true; // Optional
    }
    if (step == 5) {
      // Attendance Validation
      double? att = double.tryParse(_attendanceCtrl.text);
      if (att == null) return false;
      if (att < 0 || att > 5) {
        _showError("Attendance must be between 0 and 5");
        return false;
      }
      _attendance = att;
      return true;
    }
    return true; // Step 6 is Target
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _save() async {
    // Practical handled by auto 30 in calculator, but we can save null or 30.
    // User: "consider it 30/35 at all times".
    if (_isPractical == true) {
      _practical = 30.0;
    } else {
      _practical = null;
    }

    GradeSubject newSubject = GradeSubject(
      id: widget.subject?.id ?? const Uuid().v4(),
      name: _subjectName,
      isPractical: _isPractical!,
      cia1: _cia1!,
      cia2: _cia2!,
      cia3: _cia3,
      practical: _practical,
      attendance:
          _attendance, // Defaulted to 5, not asked nicely in this flow (optional step skipped for speed)
      targetPercent: _targetPercent,
    );

    await GradeStorageService().saveSubject(newSubject);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: isDark ? Colors.white : Colors.black),
          onPressed: _prevPage,
        ),
        title: Row(
          children: List.generate(_totalSteps, (index) {
            return Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: index <= _currentStep
                      ? (isDark ? Colors.blueAccent : Colors.blue)
                      : (isDark ? Colors.white10 : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        actions: [
          if (widget.subject != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _confirmDelete,
            )
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStep1Subject(isDark),
          _buildStep2Type(isDark),
          _buildStep3Cia1(isDark),
          _buildStep4Cia2(isDark),
          _buildStep5Cia3(isDark),
          _buildStep6Attendance(isDark), // New Step
          _buildStep7Target(isDark), // Renamed from 6
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ElevatedButton(
          onPressed: _nextPage,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            _currentStep == _totalSteps - 1
                ? (widget.subject != null ? "Update Subject" : "Save & Track")
                : "Next",
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Delete Subject?"),
              content: const Text("This cannot be undone."),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel")),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx); // Close dialog
                    await GradeStorageService()
                        .deleteSubject(widget.subject!.id);
                    if (mounted) Navigator.pop(context, true); // Close screen
                  },
                  child:
                      const Text("Delete", style: TextStyle(color: Colors.red)),
                )
              ],
            ));
  }

  Widget _buildStep1Subject(bool isDark) {
    final provider = context.read<AttendanceProvider>();
    final suggestions = provider.subjects.map((s) => s.name).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Select Subject",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Choose from your attendance list or type a new one.",
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 32),
          if (suggestions.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions.map((name) {
                final isSelected = name == _subjectName;
                return ChoiceChip(
                  label: Text(name),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _subjectName = selected ? name : "";
                      _customSubjectCtrl.text = _subjectName;
                    });
                  },
                  selectedColor: isDark
                      ? Colors.blueAccent.withOpacity(0.3)
                      : Colors.blue.shade100,
                  backgroundColor:
                      isDark ? Colors.white10 : Colors.grey.shade100,
                  labelStyle: TextStyle(
                      color: isSelected
                          ? (isDark ? Colors.blueAccent : Colors.blue.shade900)
                          : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
          ],
          TextFormField(
            controller: _customSubjectCtrl,
            onChanged: (val) => setState(() => _subjectName = val),
            decoration: InputDecoration(
              labelText: "Or Type Subject Name",
              filled: true,
              fillColor: isDark ? Colors.white10 : Colors.white,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Type(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Subject Type",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("How is this subject marked?",
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 40),
          _typeCard(
            title: "Theory Only",
            subtitle: "100 Marks Total\n(45 CIA + 50 EndSem + 5 Att)",
            isSelected: _isPractical == false,
            onTap: () => setState(() => _isPractical = false),
            isDark: isDark,
            icon: Icons.book,
          ),
          const SizedBox(height: 16),
          _typeCard(
            title: "Theory + Practical",
            subtitle: "100 Marks Total\n(30 CIA + 35 Prac + 30 EndSem + 5 Att)",
            isSelected: _isPractical == true,
            onTap: () => setState(() => _isPractical = true),
            isDark: isDark,
            icon: Icons.science,
          ),
        ],
      ),
    );
  }

  Widget _typeCard(
      {required String title,
      required String subtitle,
      required bool isSelected,
      required VoidCallback onTap,
      required bool isDark,
      required IconData icon}) {
    Color activeColor = isDark ? Colors.blueAccent : Colors.blue;
    Color bg = isSelected
        ? activeColor.withOpacity(0.1)
        : (isDark ? Colors.white10 : Colors.white);
    Color border = isSelected
        ? activeColor
        : (isDark ? Colors.white12 : Colors.grey.shade300);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: isSelected ? activeColor : Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? activeColor
                              : (isDark ? Colors.white : Colors.black))),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.grey[600])),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: activeColor),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3Cia1(bool isDark) {
    return _bgInputStep(
      title: "CIA 1 Marks",
      subtitle: "Enter marks obtained out of 20.",
      controller: _cia1Ctrl,
      isDark: isDark,
      max: 20, // Usually 20
    );
  }

  Widget _buildStep4Cia2(bool isDark) {
    return _bgInputStep(
      title: "CIA 2 Marks",
      subtitle: "Enter marks obtained out of 50.",
      controller: _cia2Ctrl,
      isDark: isDark,
      max: 50, // Usually 50
    );
  }

  Widget _buildStep5Cia3(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("CIA 3 Marks",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Optional. Leave empty if not conducted yet.",
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 40),
          TextFormField(
            controller: _cia3Ctrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: "--",
              filled: true,
              fillColor: isDark ? Colors.white10 : Colors.grey.shade50,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              suffixText: "/ 20",
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              onPressed: () {
                _cia3Ctrl.clear();
                _nextPage(); // Skip implies next
              },
              icon: const Icon(Icons.skip_next, color: Colors.grey),
              label: const Text("Skip / Not Conducted",
                  style: TextStyle(color: Colors.grey)),
            ),
          ),
          if (_isPractical == true) ...[
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withOpacity(0.3))),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                      child: Text(
                          "Lab marks will be considered as 30/35 for prediction.",
                          style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold))),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _bgInputStep(
      {required String title,
      required String subtitle,
      required TextEditingController controller,
      required bool isDark,
      required double max}) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 60),
          TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
                hintText: "0",
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.grey.shade50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none),
                suffixText: "/ ${max.toInt()}",
                suffixStyle: const TextStyle(fontSize: 20, color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildStep6Attendance(bool isDark) {
    return _bgInputStep(
      title: "Attendance Marks",
      subtitle: "Enter marks out of 5",
      controller: _attendanceCtrl,
      isDark: isDark,
      max: 5,
    );
  }

  Widget _buildStep7Target(bool isDark) {
    // We need to calculate result live here to show preview
    GradeResult? result;

    // Construct temp obj
    try {
      double c1 = double.tryParse(_cia1Ctrl.text) ?? 0;
      double c2 = double.tryParse(_cia2Ctrl.text) ?? 0;
      double? c3 =
          _cia3Ctrl.text.isNotEmpty ? double.tryParse(_cia3Ctrl.text) : null;
      double att = double.tryParse(_attendanceCtrl.text) ?? 5.0; // Use input

      // Force practical 30 logic here for preview consistency
      double? p = (_isPractical == true) ? 30.0 : null;

      GradeSubject temp = GradeSubject(
          id: "temp",
          name: _subjectName,
          isPractical: _isPractical!,
          cia1: c1,
          cia2: c2,
          cia3: c3,
          practical: p,
          attendance: att, // Use actual
          targetPercent: _targetPercent);
      result = GradeCalculator.calculate(temp);
    } catch (e) {
      // ignore
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text("Set Target",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          Text("${_targetPercent.toInt()}%",
              style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: Colors.blue)),
          Slider(
            value: _targetPercent,
            min: 40,
            max: 100,
            divisions: 60,
            activeColor: Colors.blue,
            onChanged: (val) {
              setState(() => _targetPercent = val);
            },
          ),
          const SizedBox(height: 30),
          if (result != null) _buildResultCard(result, isDark),
        ],
      ),
    );
  }

  Widget _buildResultCard(GradeResult res, bool isDark) {
    Color color = _getColorForDifficulty(res.difficulty);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          Text(
              res.difficulty == GradeDifficulty.impossible
                  ? "IMPOSSIBLE"
                  : (res.difficulty == GradeDifficulty.autoSecured
                      ? "SECURED"
                      : "REQUIRED END SEM"),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: color)),
          const SizedBox(height: 16),
          if (res.difficulty != GradeDifficulty.impossible &&
              res.difficulty != GradeDifficulty.autoSecured) ...[
            Text("${res.requiredEndSem.toStringAsFixed(1)}",
                style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    color: color)),
            Text("/ 100",
                style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
          const SizedBox(height: 16),
          Text(res.suggestion,
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  Color _getColorForDifficulty(GradeDifficulty diff) {
    switch (diff) {
      case GradeDifficulty.easy:
        return Colors.green;
      case GradeDifficulty.moderate:
        return Colors.orange;
      case GradeDifficulty.hard:
        return Colors.deepOrange;
      case GradeDifficulty.extremelyTough:
        return Colors.red;
      case GradeDifficulty.impossible:
        return Colors.red.shade900;
      case GradeDifficulty.autoSecured:
        return Colors.blue;
    }
  }
}
