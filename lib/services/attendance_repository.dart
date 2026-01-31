import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import '../models/subject_stats.dart';
import 'login_service.dart';

class AttendanceRepository {
  static const String _baseUrl = 'https://kp.christuniversity.in/KnowledgePro';
  static const String _homeUrl = '$_baseUrl/StudentLoginAction.do';
  static const String _summaryUrl =
      '$_baseUrl/studentWiseAttendanceSummary.do?method=getIndividualStudentWiseSubjectAndActivityAttendanceSummary';
  static const String _detailsUrl =
      '$_baseUrl/studentWiseAttendanceSummary.do?method=getStudentAbscentWithCocularLeave';

  Future<Map<String, dynamic>> fetchAttendance(
      String initialCookieHeader) async {
    final client = http.Client();
    final Map<String, String> cookieJar =
        LoginService.parseCookieToMap(initialCookieHeader);

    try {
      print(
          'DEBUG: AttendanceRepository v3 - Robust Duty Leave Check'); // Force update
      final Map<String, String> headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
        'Accept-Language': 'en-US,en;q=0.9',
        'Upgrade-Insecure-Requests': '1',
        'Sec-Fetch-Site': 'same-origin',
        'Cookie': LoginService.buildCookieHeader(cookieJar),
        'Referer':
            'https://kp.christuniversity.in/KnowledgePro/StudentLogin.do',
      };

      // Step 0: Fetch Home Page (Dashboard) for Name
      print('DEBUG: Fetching Home URL for Name: $_homeUrl');
      String studentName = "Student";
      try {
        final homeResponse =
            await client.get(Uri.parse(_homeUrl), headers: headers);
        if (homeResponse.statusCode == 200) {
          print(
              "DEBUG: Home Page HTML (First 500 chars): ${homeResponse.body.substring(0, homeResponse.body.length > 500 ? 500 : homeResponse.body.length)}");
          // Update cookies if any
          if (homeResponse.headers['set-cookie'] != null) {
            cookieJar.addAll(LoginService.parseCookieToMap(
                homeResponse.headers['set-cookie']!));
            headers['Cookie'] = LoginService.buildCookieHeader(cookieJar);
          }

          final homeDoc = parser.parse(homeResponse.body);
          // Strategy 1: span.name
          final nameSpan = homeDoc.querySelector('span.name');
          if (nameSpan != null) {
            studentName = nameSpan.text.trim();
            print('DEBUG: Found Name via span.name: $studentName');
          }

          // Strategy 2: div.proname2
          if (studentName == "Student" || studentName.isEmpty) {
            final proNameDiv = homeDoc.querySelector('div.proname2');
            if (proNameDiv != null) {
              // Expected text: "Name : STUDENT NAME ..."
              final rawText =
                  proNameDiv.text.replaceAll(RegExp(r'\s+'), ' ').trim();
              print('DEBUG: Found proname2 div text: $rawText');
              if (rawText.contains('Name :')) {
                final parts = rawText.split('Name :');
                if (parts.length > 1) {
                  // Take the part after "Name :", often followed by other text or newline,
                  // but user snippet shows it's inside a table cell, so text might be clean.
                  // Clean up any trailing garbage if necessary
                  String candidate = parts[1].trim();
                  // Heuristic: Name is usually all caps or CamelCase, stops at next label if any?
                  // For now, assume it takes the rest of the text node or reasonable length
                  studentName = candidate;
                  print('DEBUG: Parsed Name via proname2: $studentName');
                }
              }
            }
          }

          // Strategy 3: Regex on full HTML
          if (studentName == "Student" || studentName.isEmpty) {
            final htmlContent = homeResponse.body;
            // 1. Look for bold Name tag: <b>Name :</b> ...
            var regex = RegExp(r'Name\s*:\s*<\/b>\s*<span[^>]*>([^<]+)<\/span>',
                caseSensitive: false);
            var match = regex.firstMatch(htmlContent);

            // 2. Look for "Name : " in general text
            if (match == null) {
              regex =
                  RegExp(r'Name\s*:\s*([A-Za-z\s\.]+)', caseSensitive: false);
              // We need to be careful not to match "Name : Subject Name" etc.
              // So maybe look for something that is NOT "Subject" or "Total"
              final matches = regex.allMatches(homeDoc.body?.text ?? "");
              for (var m in matches) {
                final val = m.group(1)?.trim() ?? "";
                if (val.isNotEmpty &&
                    !val.toLowerCase().contains("subject") &&
                    val.length > 3) {
                  studentName = val;
                  print('DEBUG: Found Name via General Regex: $studentName');
                  break;
                }
              }
            } else {
              studentName = match.group(1)?.trim() ?? "Student";
              print('DEBUG: Found Name via HTML Regex: $studentName');
            }
          }

          if (studentName == "Student") {
            print(
                'DEBUG: Failed to extract name from Home Page with all strategies.');
          }
        }
      } catch (e) {
        print('DEBUG: Failed to fetch Home Page for name: $e');
      }

      // Step A: Fetch Summary
      print('DEBUG: Fetching Summary URL: $_summaryUrl');
      final summaryResponse =
          await client.get(Uri.parse(_summaryUrl), headers: headers);
      if (summaryResponse.statusCode != 200)
        throw Exception('Failed to fetch summary');

      if (summaryResponse.headers['set-cookie'] != null) {
        cookieJar.addAll(LoginService.parseCookieToMap(
            summaryResponse.headers['set-cookie']!));
        headers['Cookie'] = LoginService.buildCookieHeader(cookieJar);
      }

      final summaryDocument = parser.parse(summaryResponse.body);
      if (summaryDocument.querySelector('input[type="password"]') != null) {
        throw Exception('Session Invalid: Redirected to Login Page.');
      }

      print(
          'DEBUG: Summary Page Fetched. Body Length: ${summaryResponse.body.length}');

      // Fallback Name Parsing from Summary Tables
      if (studentName == "Student") {
        // Strategy 4: Inspect first few tables for "Name" key
        final summaryTables = summaryDocument.querySelectorAll('table');
        for (var i = 0; i < summaryTables.length && i < 5; i++) {
          final rows = summaryTables[i].querySelectorAll('tr');
          for (var row in rows) {
            final cells = row.querySelectorAll('td');
            for (var j = 0; j < cells.length; j++) {
              final text = cells[j].text.trim().toLowerCase();
              if (text == 'name' || text == 'student name') {
                // Check next cell
                if (j + 1 < cells.length) {
                  final val = cells[j + 1].text.trim();
                  if (val.isNotEmpty && val.length > 2) {
                    studentName = val;
                    print(
                        "DEBUG: Found Name in Summary Table $i: $studentName");
                    break;
                  }
                }
              }
              // Sometimes content is "Name : [Actual Name]" in one cell
              if (text.startsWith('name') && text.contains(':')) {
                final parts = text.split(':');
                if (parts.length > 1) {
                  final val = parts[1].trim();
                  if (val.isNotEmpty && val.length > 2) {
                    studentName = val;
                    print(
                        "DEBUG: Found Name via Cell Split in Summary Table $i: $studentName");
                    break;
                  }
                }
              }
            }
            if (studentName != "Student") break;
          }
          if (studentName != "Student") break;
        }
      }

      // Fallback Name Parsing from Summary if Home failed? (Regex based)
      if (studentName == "Student") {
        final bodyText = summaryDocument.body?.text ?? "";
        // Look for "Name : [Name]" allowing for potential newlines or tabs
        final nameMatch =
            RegExp(r'Name\s*[:|-]\s*([A-Za-z\s\.]{3,50})').firstMatch(bodyText);
        if (nameMatch != null) {
          final candidate = nameMatch.group(1)?.trim();
          if (candidate != null &&
              !candidate.toLowerCase().contains("subject")) {
            studentName = candidate;
            print('DEBUG: Found Name via Summary Fallback: $studentName');
          }
        }
      }

      final Map<String, SubjectStats> statsMap =
          _parseSummary(summaryResponse.body);
      print('DEBUG: Parsed ${statsMap.length} subjects from Summary.');

      // Step B: Fetch Details
      headers['Referer'] = _summaryUrl;
      print('DEBUG: Fetching Details URL: $_detailsUrl');
      final detailsResponse =
          await client.get(Uri.parse(_detailsUrl), headers: headers);
      if (detailsResponse.statusCode != 200)
        throw Exception('Failed to fetch details');

      print(
          'DEBUG: Details Page Fetched. Body Length: ${detailsResponse.body.length}');
      _parseDetailsAndMerge(detailsResponse.body, statsMap);

      return {
        'name': studentName,
        'stats': statsMap,
      };
    } finally {
      client.close();
    }
  }

  Map<String, SubjectStats> _parseSummary(String htmlBody) {
    final document = parser.parse(htmlBody);
    final Map<String, SubjectStats> map = {};
    final form =
        document.querySelector('form[name="studentWiseAttendanceSummaryForm"]');
    final rows = form?.querySelectorAll('tr') ?? [];

    for (var row in rows) {
      final cells = row.children;
      if (cells.length < 3) continue;

      String slNo = cells[0].text.trim().replaceAll('.', '');
      if (!RegExp(r'^\d+$').hasMatch(slNo)) continue;

      String rawName = cells[1].text.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (rawName.toLowerCase() == 'total') continue;

      double cond = 0, abs = 0;
      bool found = false;

      final inner = cells[2].querySelector('table');
      if (inner != null) {
        for (var iRow in inner.querySelectorAll('tr')) {
          final iCells = iRow.querySelectorAll('td');
          if (iCells.length >= 5) {
            double? c = double.tryParse(iCells[1].text.trim());
            double? a = double.tryParse(iCells[3].text.trim());
            if (c != null && a != null) {
              cond += c;
              abs += a;
              found = true;
            }
          }
        }
      }

      if (found) {
        map[rawName] = SubjectStats(
          code: "UNMAPPED",
          name: rawName,
          totalHours: cond.toInt(),
          blueAbsents: abs.toInt(),
          greenDutyLeaves: 0,
        );
      }
    }
    return map;
  }

  void _parseDetailsAndMerge(
      String htmlBody, Map<String, SubjectStats> statsMap) {
    final document = parser.parse(htmlBody);
    final tables = document.querySelectorAll('table');

    print('DEBUG: Details Logic v3 - Legend Based Mapping & Cell Iteration');

    // --- PHASE 1: Build robust Name -> Code Map from the Legend Table ---
    final Map<String, String> nameToCodeMap = {};

    for (var table in tables) {
      // Heuristic: Legend table has no big headers, just cells with "Name (Code)"
      final cells = table.querySelectorAll('td');
      for (var cell in cells) {
        final text = cell.text.trim();
        // Regex: Matches "Subject Name (SUBJECTCODE)"
        final match = RegExp(r'(.+?)\s*\((.+?)\)$').firstMatch(text);
        if (match != null) {
          String rawName = match.group(1)!.trim();
          String rawCode = match.group(2)!.trim();

          // Normalize Key: lowercase, remove spaces/punctuation for fuzzy matching
          String normalizedName =
              rawName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

          if (normalizedName.isNotEmpty && rawCode.isNotEmpty) {
            nameToCodeMap[normalizedName] = rawCode;
          }
        }
      }
    }

    print(
        'DEBUG: Constructed Legend Map (${nameToCodeMap.length} entries): $nameToCodeMap');

    // --- PHASE 2: Re-Key the Stats Map to use CODES ---
    final Map<String, SubjectStats> codeKeyedStats = {};
    final List<String> unmappedSubjects = [];

    statsMap.forEach((summaryName, stats) {
      String normSummaryName =
          summaryName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

      // 1. Try exact normalized match
      String? matchedCode = nameToCodeMap[normSummaryName];

      // 2. Fallback: Contains match
      if (matchedCode == null) {
        for (var legendName in nameToCodeMap.keys) {
          if (legendName.contains(normSummaryName) ||
              normSummaryName.contains(legendName)) {
            if (legendName.length > 5 && normSummaryName.length > 5) {
              matchedCode = nameToCodeMap[legendName];
              break;
            }
          }
        }
      }

      // 3. Fallback: Special cases (like Wireless Networks IOT mismatch)
      if (matchedCode == null) {
        if (normSummaryName.contains('wireless') &&
            normSummaryName.contains('networks')) {
          for (var entry in nameToCodeMap.entries) {
            if (entry.value.contains('CSEIOT') || entry.value.contains('IOT')) {
              matchedCode = entry.value;
            }
          }
        }
      }

      if (matchedCode != null) {
        codeKeyedStats[matchedCode!] = SubjectStats(
          code: matchedCode!,
          name: stats.name,
          totalHours: stats.totalHours,
          blueAbsents: stats.blueAbsents,
          greenDutyLeaves: 0,
        );
      } else {
        print('DEBUG: Create unmapped entry for $summaryName');
        unmappedSubjects.add(summaryName);
        codeKeyedStats[summaryName] = stats;
      }
    });

    statsMap.clear();
    statsMap.addAll(codeKeyedStats);
    print('DEBUG: Re-keyed Stats Map keys: ${statsMap.keys.toList()}');

    // --- PHASE 3: Process Attendance Rows (Using Codes) ---
    // Note: processedRowHashes and totalProcessedRows variables should be declared if not already,
    // but in this context they were re-declared.
    // We will assume they are needed here for the logic block.
    final Set<String> processedRowHashes = {};
    int totalProcessedRows = 0;

    // We only want the FIRST table with class 'table-striped table-bordered table-condensed'
    // or similar structure. The summary tables are often at the bottom.
    // Heuristic: The main table usually has the most rows. Or index 0 of specific class.

    Element? mainTable;
    for (var table in tables) {
      if (table.classes.contains('table-striped') &&
          table.classes.contains('table-bordered') &&
          table.classes.contains('table-condensed') &&
          table.querySelector('th')?.text.toLowerCase().contains('date') ==
              true) {
        mainTable = table;
        break;
      }
    }
    // Fallback: Use the previous heuristic if specific classes aren't consistent
    if (mainTable == null) {
      for (var table in tables) {
        if (table.text.toLowerCase().contains('date') &&
            table.text.toLowerCase().contains('period')) {
          mainTable = table;
          break;
        }
      }
    }

    if (mainTable != null) {
      final rows = mainTable.querySelectorAll('tr');
      // Skip header row (index 0 usually)
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        final cells = row.querySelectorAll('td');

        // Basic validation: Main table rows usually have ~10 columns (Date, Day, P1-7, Total)
        if (cells.length < 9) continue;

        // Deduplication
        String rowHash = row.text.replaceAll(RegExp(r'\s+'), '').trim();
        if (processedRowHashes.contains(rowHash)) continue;
        processedRowHashes.add(rowHash);
        totalProcessedRows++;

        String rowText = row.text.replaceAll(RegExp(r'\s+'), ' ').trim();

        // Check Periods 1 to 7 (Indices 2 to 8)
        // Ensure index is within bounds
        int loopEnd = (cells.length >= 9)
            ? 9
            : cells.length; // usually 2 to 8 inclusive = 7 periods

        for (int p = 2; p < loopEnd; p++) {
          final cell = cells[p];
          final text = cell.text.trim();

          if (text.isEmpty) continue; // Present (empty cell)

          // If text is not empty, it's either Absent or Duty Leave
          // Map text to Subject Code
          String? subjectCode;
          if (statsMap.containsKey(text)) {
            subjectCode = text;
          } else {
            // Try to find if this matches any code in our map (maybe unmapped)
            // This relies on the text being the CODE itself, which it usually is in details
          }

          if (subjectCode != null) {
            // Check for Green Font Tag specifically as per user instruction
            bool isOD = false;
            final fontTag = cell.querySelector('font');
            if (fontTag != null) {
              final color = fontTag.attributes['color']?.toLowerCase() ?? '';
              if (color == 'green') isOD = true;
            }
            // Also check style attribute as backup
            if (!isOD) {
              final style = (cell.attributes['style'] ?? '') +
                  (fontTag?.attributes['style'] ?? '');
              if (style.toLowerCase().contains('green')) isOD = true;
            }

            if (isOD) {
              statsMap[subjectCode]!.greenDutyLeaves++;
              print(
                  'DEBUG: Found DUTY LEAVE for $subjectCode (Col $p) | Row: $rowText');
            } else {
              // It's a regular absent.
              // We don't need to increment 'blueAbsents' because that comes from the Summary page
              // which is the "source of truth" for total absents.
              // However, validation: If summary says X absents, we expect X non-green cells here.
            }
          }
        }
      }
    }

    print("DEBUG: Total Details Rows Processed: $totalProcessedRows");

    // Final cleanup: If we have unmapped subjects that never found a matching code in details,
    // they remain as is.
  }
}
