import 'package:attcalci/models/grade_subject.dart';

enum GradeDifficulty {
  easy,
  moderate,
  hard,
  extremelyTough,
  impossible,
  autoSecured // Target already met
}

class GradeResult {
  final double
      requiredEndSem; // If -1, implies impossible or secured based on context, but we use flags
  final double requiredCia3; // If calculated
  final GradeDifficulty difficulty;
  final String suggestion;
  final double currentTotal; // Current marks secured

  GradeResult({
    required this.requiredEndSem,
    required this.requiredCia3,
    required this.difficulty,
    required this.suggestion,
    required this.currentTotal,
  });
}

class GradeCalculator {
  static GradeResult calculate(GradeSubject subject) {
    if (subject.isPractical) {
      return _calculateTheoryPlusPractical(subject);
    } else {
      return _calculateTheoryOnly(subject);
    }
  }

  // CASE 1: THEORY ONLY SUBJECT
  // Total = 100 Marks
  // CIA Max Raw = 90 (20 + 50 + 20) -> Scaled to 45 (Factor 0.5)
  // End Semester Scaled Max = 50 -> Raw 100 (Factor 0.5)
  // Attendance = 5 marks
  static GradeResult _calculateTheoryOnly(GradeSubject subject) {
    double cia1 = subject.cia1;
    double cia2 = subject.cia2;
    double attendance = subject.attendance;
    double targetMarks = subject.targetPercent;

    // Step A: Determine Current CIA Status
    double? cia3 = subject.cia3;

    // Step B: Calculate Known Scaled Marks

    // Calculate assumed CIA 3 based on Target %
    double assumedCia3;
    if (cia3 != null) {
      assumedCia3 = cia3;
    } else {
      // 20 * (Target% / 100)
      assumedCia3 = 20.0 * (targetMarks / 100.0);
    }

    double totalRawCia = cia1 + cia2 + assumedCia3;
    double scaledCia = totalRawCia * 0.5; // 90 -> 45

    double knownTotal = scaledCia + attendance;

    // Step C: Required Scaled EndSem
    double neededForTarget = targetMarks - knownTotal;

    // Step D: Convert to Raw EndSem (Out of 100)
    // Scaled = Raw * 0.5 => Raw = Scaled / 0.5 = Scaled * 2
    double requiredEndSemRaw = neededForTarget * 2.0;

    // Suggestion Construct
    String suggestion = "";
    if (cia3 == null) {
      suggestion =
          "Assuming you score ${assumedCia3.toStringAsFixed(1)}/20 in CIA 3 (your target %).\n"
          "You need ${requiredEndSemRaw.toStringAsFixed(1)} / 100 in End Sem.\n"
          "Tip: Scoring more in CIA 3 reduces this requirement! 📉";
    } else {
      GradeDifficulty diff = _getDifficulty(requiredEndSemRaw, 100);
      suggestion = _generateSuggestion(diff, requiredEndSemRaw, 100);
    }

    // Constraints
    if (requiredEndSemRaw <= 0) {
      return GradeResult(
        requiredEndSem: 0,
        requiredCia3: 0,
        difficulty: GradeDifficulty.autoSecured,
        suggestion: "Target secured! 🎉",
        currentTotal: knownTotal,
      );
    }

    if (requiredEndSemRaw > 100) {
      return GradeResult(
        requiredEndSem: requiredEndSemRaw,
        requiredCia3: assumedCia3,
        difficulty: GradeDifficulty.impossible,
        suggestion: "Impossible. Requires > 100 in EndSem.",
        currentTotal: knownTotal,
      );
    }

    // Min Pass Check
    if (requiredEndSemRaw < 40 && cia3 != null) {
      // Only warn if CIA 3 is actual, otherwise message gets cluttered
    }

    GradeDifficulty diff = _getDifficulty(requiredEndSemRaw, 100);

    // If suggestion wasn't set (via Null CIA 3 check above)
    if (suggestion.isEmpty) {
      suggestion = _generateSuggestion(diff, requiredEndSemRaw, 100);
    }

    return GradeResult(
        requiredEndSem: requiredEndSemRaw,
        requiredCia3: assumedCia3,
        difficulty: diff,
        suggestion: suggestion,
        currentTotal: knownTotal);
  }

  // CASE 2: THEORY + PRACTICAL SUBJECT
  // Total = 100 Marks
  // CIA Max Raw = 90 (20 + 50 + 20) -> Scaled to 30 (Factor 1/3)
  // Practical Max = 35 (Raw is 35? User said "Lab assumed = 28 / 35". So seems 1:1)
  // End Semester Scaled Max = 30 -> Raw 100 (Factor 0.3)
  // Attendance = 5 marks
  static GradeResult _calculateTheoryPlusPractical(GradeSubject subject) {
    double cia1 = subject.cia1;
    double cia2 = subject.cia2;
    double? cia3 = subject.cia3;

    double attendance = subject.attendance;
    double targetMarks = subject.targetPercent;

    // Scaling CIA: Raw / 3
    // Scenario: CIA 3 might be null.

    // User Request: "if they entered 70% use 14 (70%) and tell how much required in endsem"

    // Calculate assumed CIA 3 based on Target %
    double assumedCia3;
    if (cia3 != null) {
      assumedCia3 = cia3;
    } else {
      // 20 * (Target% / 100)
      assumedCia3 = 20.0 * (targetMarks / 100.0);
    }

    double totalRawCia = cia1 + cia2 + assumedCia3;
    double scaledCia = totalRawCia / 3.0;

    // Practical: Fixed at 30 if not entered
    double practical = subject.practical ?? 30.0;

    double knownTotal = scaledCia + practical + attendance;
    double neededForTarget = targetMarks - knownTotal;

    // EndSem Convert: Scaled = Raw * 0.3 => Raw = Scaled / 0.3
    double requiredEndSemRaw = neededForTarget / 0.3;

    // Analysis for Suggestion
    String suggestion = "";
    if (cia3 == null) {
      suggestion =
          "Assuming you score ${assumedCia3.toStringAsFixed(1)}/20 in CIA 3 (your target %).\n"
          "You need ${requiredEndSemRaw.toStringAsFixed(1)} / 100 in End Sem.\n"
          "Tip: Scoring more in CIA 3 reduces this requirement! 📉";
    } else {
      GradeDifficulty diff = _getDifficulty(requiredEndSemRaw, 100);
      suggestion = _generateSuggestion(diff, requiredEndSemRaw, 100);
    }

    if (requiredEndSemRaw <= 0) {
      return GradeResult(
        requiredEndSem: 0,
        requiredCia3: 0,
        difficulty: GradeDifficulty.autoSecured,
        suggestion: "With 30 in Lab & current internals, you've secured it! 🎉",
        currentTotal: knownTotal,
      );
    }

    if (requiredEndSemRaw > 100) {
      return GradeResult(
        requiredEndSem: requiredEndSemRaw,
        requiredCia3: assumedCia3,
        difficulty: GradeDifficulty.impossible,
        suggestion:
            "Even with ${assumedCia3.toStringAsFixed(1)} in CIA 3, target is impossible (>100 EndSem needed).",
        currentTotal: knownTotal,
      );
    }

    // Recalculate diff for non-null CIA3 case or just display generic difficulty for null case?
    // The card uses difficulty enum for color, so we need it.
    GradeDifficulty diff = _getDifficulty(requiredEndSemRaw, 100);

    return GradeResult(
        requiredEndSem: requiredEndSemRaw,
        requiredCia3: assumedCia3,
        difficulty: diff,
        suggestion: suggestion,
        currentTotal: knownTotal);
  }

  static GradeDifficulty _getDifficulty(double requiredRaw, double maxRaw) {
    // Universal 100-scale difficulty
    if (requiredRaw <= 50) return GradeDifficulty.easy;
    if (requiredRaw <= 70) return GradeDifficulty.moderate;
    if (requiredRaw <= 85) return GradeDifficulty.hard;
    if (requiredRaw <= 100) return GradeDifficulty.extremelyTough;
    return GradeDifficulty.impossible;
  }

  static String _generateSuggestion(
      GradeDifficulty diff, double req, double max) {
    if (req < 40)
      return "Target is easy, but ensure you score at least 40/100 to pass!";

    switch (diff) {
      case GradeDifficulty.easy:
        return "Smooth sailing! ⛵ Just revise basics.";
      case GradeDifficulty.moderate:
        return "Doable. Focus on weak topics.";
      case GradeDifficulty.hard:
        return "Grind mode on. 📚 Solving past papers is a must.";
      case GradeDifficulty.extremelyTough:
        return "Villain Arc required. 😈 Perfection needed.";
      case GradeDifficulty.impossible:
        return "Target unrealistic. 🛑 Lower the bar?";
      case GradeDifficulty.autoSecured:
        return "You're golden. 🌟";
    }
  }
}
