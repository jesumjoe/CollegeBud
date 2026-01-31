import 'package:flutter/material.dart';
import 'package:attcalci/models/grade_subject.dart';
import 'package:attcalci/services/grade_storage_service.dart';
import 'package:attcalci/screens/grade_entry_screen.dart';
import 'package:attcalci/utils/grade_calculator.dart';

class GradeDashboardScreen extends StatefulWidget {
  const GradeDashboardScreen({super.key});

  @override
  State<GradeDashboardScreen> createState() => _GradeDashboardScreenState();
}

class _GradeDashboardScreenState extends State<GradeDashboardScreen> {
  final GradeStorageService _storage = GradeStorageService();
  List<GradeSubject> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _storage.loadSubjects();
    setState(() {
      _subjects = data;
      _isLoading = false;
    });
  }

  void _navigateToAddEdit([GradeSubject? subject]) async {
    final result = await Navigator.push(context,
        MaterialPageRoute(builder: (_) => GradeEntryScreen(subject: subject)));

    if (result == true) {
      _loadData(); // Refresh if save happened
    }
  }

  void _deleteSubject(String id) async {
    await _storage.deleteSubject(id);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Grade Companion",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEdit(),
        backgroundColor:
            isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32),
        label: const Text("Add Subject", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_outlined,
                          size: 80, color: Colors.grey.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text("No subjects tracked yet.",
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text("Tap 'Add Subject' to start prediction.",
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _subjects.length,
                  itemBuilder: (context, index) {
                    final subject = _subjects[index];
                    final result = GradeCalculator.calculate(subject);

                    return Dismissible(
                      key: Key(subject.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _deleteSubject(subject.id),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: GestureDetector(
                        onTap: () => _navigateToAddEdit(subject),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ],
                            border: Border.all(
                                color: isDark
                                    ? Colors.white12
                                    : const Color(0xFFE0E0E0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(subject.name,
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white10
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                        subject.isPractical
                                            ? "Theory + Practical"
                                            : "Theory Only",
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black54)),
                                  )
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Target",
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.white54
                                                  : Colors.grey)),
                                      Text("${subject.targetPercent.toInt()}%",
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text("Required EndSem",
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.white54
                                                  : Colors.grey)),
                                      Text(
                                          result.difficulty ==
                                                  GradeDifficulty.impossible
                                              ? "Impossible"
                                              : (result.difficulty ==
                                                      GradeDifficulty
                                                          .autoSecured
                                                  ? "Secured"
                                                  : "${result.requiredEndSem.toStringAsFixed(1)} / 100"),
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: _getColorForDifficulty(
                                                  result.difficulty))),
                                    ],
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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
