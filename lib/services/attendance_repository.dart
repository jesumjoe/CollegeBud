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

          // Strategy 3: Regex on full HTML (in case parser strips something odd)
          if (studentName == "Student" || studentName.isEmpty) {
            final htmlContent = homeResponse.body;
            // Look for <b>Name :</b> <span class="name">NAME</span>
            final regex = RegExp(
                r'Name\s*:\s*<\/b>\s*<span[^>]*>([^<]+)<\/span>',
                caseSensitive: false);
            final match = regex.firstMatch(htmlContent);
            if (match != null) {
              studentName = match.group(1)?.trim() ?? "Student";
              print('DEBUG: Found Name via Regex on HTML: $studentName');
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

      // Fallback Name Parsing from Summary if Home failed?
      if (studentName == "Student") {
        final bodyText = summaryDocument.body?.text ?? "";
        final nameMatch =
            RegExp(r'Name\s*:\s*([A-Za-z\s\.]+)').firstMatch(bodyText);
        if (nameMatch != null) {
          studentName = nameMatch.group(1)?.trim() ?? "Student";
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

    Element? targetTable;
    final tables = document.querySelectorAll('table');
    print('DEBUG: Found ${tables.length} tables in Summary Page.');

    // Heuristics to find the main outer table
    for (var table in tables) {
      if (table.className.contains('table-striped')) {
        targetTable = table;
        print('DEBUG: Found Summary Table via class name.');
        break;
      }
    }

    if (targetTable == null) {
      for (var table in tables) {
        // Check for 'Subject Name' in th/td
        if (table.innerHtml.toLowerCase().contains('subject name')) {
          // Ensure it's not just a wrapper by checking if it contains nested tables?
          // Actually, the outer table DOES contain nested tables.
          // We prefer the one that has 'Subject Name' in its direct header if possible.
          if (table.querySelectorAll('tr').length > 1) {
            // Basic sanity check
            targetTable = table;
            // Keep looking? No, break on first good candidate usually safest here
            break;
          }
        }
      }
    }

    if (targetTable == null) {
      print('ERROR: Summary Table NOT found!');
      return {};
    }

    // STRICT ROW ITERATION
    // Do NOT use querySelectorAll('tr') on the table, as it returns nested TRs too.
    // We must manually iterate children.
    List<Element> rows = [];
    for (var child in targetTable.children) {
      if (child.localName == 'tbody') {
        rows.addAll(child.children.where((c) => c.localName == 'tr'));
      } else if (child.localName == 'tr') {
        rows.add(child);
      }
    }

    print('DEBUG: Found ${rows.length} Outer Rows.');

    for (var row in rows) {
      final cells = row.children;
      // Outer Row Structure: [Sl.No, Subject Name, DataWrapper(NestedTable)]
      // Some rows might be headers or empty, we need at least 3 cells usually.
      if (cells.length < 3) continue;

      final subjectName = cells[1].text.trim();

      // Filter Garbage Rows
      if (subjectName.isEmpty ||
          subjectName.toLowerCase().contains('subject name') ||
          subjectName.toLowerCase().startsWith('total')) continue;

      // Inner Table Logic (Nested in 3rd cell usually, index 2)
      // Sometimes it's a div wrapping the table, or just the table.
      final innerTable = cells[2].querySelector('table');
      double totalConducted = 0;
      double totalAbsent = 0;

      if (innerTable != null) {
        // Inner rows: Here we can use querySelectorAll('tr') safely as we are scoped
        // to this specific subject, assuming no deeper nesting.
        final innerRows = innerTable.querySelectorAll('tr');

        for (var innerRow in innerRows) {
          final innerCells = innerRow.children;
          // Inner Row Expected Structure:
          // [Type(Theory/Prac), Conducted, Present, Absent, %]
          // e.g. [Theory, 24.0, 20.0, 4.0, 83.33]

          if (innerCells.length >= 4) {
            final type = innerCells[0].text.trim().toLowerCase();
            if (type.contains('attendance type')) continue; // Skip inner header

            // Index 1: Conducted
            final conductedStr = innerCells[1].text.trim();
            totalConducted += double.tryParse(conductedStr) ?? 0;

            // Index 3: Absent (Verified from user screenshot, column 4)
            final absentStr = innerCells[3].text.trim();
            totalAbsent += double.tryParse(absentStr) ?? 0;
          }
        }
      }

      print(
          'DEBUG: Parsed "$subjectName" -> Conducted: $totalConducted, Absent: $totalAbsent');

      map[subjectName] = SubjectStats(
          code: "UNKNOWN", // Will be updated in Details phase
          name: subjectName,
          totalHours: totalConducted.toInt(),
          blueAbsents: totalAbsent.toInt(), // Using correct summary data
          greenDutyLeaves: 0);
    }
    return map;
  }

  void _parseDetailsAndMerge(
      String htmlBody, Map<String, SubjectStats> statsMap) {
    final document = parser.parse(htmlBody);
    final tables = document.querySelectorAll('table');
    print('DEBUG: Found ${tables.length} tables in Details Page.');

    // 1. Mapping Table Logic
    Element? mappingTable;
    int bestMatchCount = 0;

    for (var i = 0; i < tables.length; i++) {
      final text = tables[i].text;
      int matchCount = 0;
      for (var name in statsMap.keys) {
        if (text.contains(name)) matchCount++;
      }
      if (matchCount > bestMatchCount) {
        bestMatchCount = matchCount;
        mappingTable = tables[i];
      }
    }

    if (mappingTable != null && bestMatchCount > 0) {
      final cells = mappingTable.querySelectorAll('td');
      Map<String, String> nameToCode = {};
      for (var cell in cells) {
        final text = cell.text.trim().replaceAll(RegExp(r'\s+'), ' ');
        final match = RegExp(r'(.+?)\s*\((.+?)\)').firstMatch(text);
        if (match != null) {
          String name = match.group(1)?.trim() ?? '';
          String code = match.group(2)?.trim() ?? '';
          if (name.isNotEmpty && code.isNotEmpty && code.length < 20) {
            nameToCode[name] = code;
          }
        }
      }

      nameToCode.forEach((rawName, code) {
        String? key;
        if (statsMap.containsKey(rawName))
          key = rawName;
        else {
          for (var k in statsMap.keys) {
            if (rawName.contains(k) || k.contains(rawName)) {
              key = k;
              break;
            }
          }
        }
        if (key != null) {
          final old = statsMap[key]!;
          statsMap[code] = SubjectStats(
              code: code,
              name: old.name,
              totalHours: old.totalHours,
              blueAbsents: old.blueAbsents,
              greenDutyLeaves: old.greenDutyLeaves);
          statsMap.remove(key);
          print('DEBUG: Mapped "$rawName" -> "$code"');
        }
      });
    }

    // 2. Duty Leave Parsing
    Element? detailsTable;
    for (var i = 0; i < tables.length; i++) {
      final text = tables[i].text.toLowerCase();
      if (text.contains('date') && text.contains('period')) {
        // Check nesting to avoid wrapper tables
        if (tables[i].querySelectorAll('table').isEmpty) {
          detailsTable = tables[i];
          break;
        }
      }
    }
    // Fallback
    if (detailsTable == null) {
      for (var t in tables) {
        if (t.text.toLowerCase().contains('date') &&
            t.text.toLowerCase().contains('period')) {
          detailsTable = t;
          break;
        }
      }
    }

    if (detailsTable != null) {
      final rows = detailsTable.querySelectorAll('tr');
      for (var i = 1; i < rows.length; i++) {
        final cells = rows[i].querySelectorAll('td');
        if (cells.length < 3) continue;

        // Duty Leave (Green) Logic
        // We only increment greenDutyLeaves here.
        // We DO NOT touch blueAbsents as that comes from Summary.

        String rowStyle = rows[i].attributes['style']?.toLowerCase() ?? '';

        // Iterate periods (skip first 2 columns: Date, Day)
        for (var j = 2; j < cells.length - 1; j++) {
          final cell = cells[j];
          final text = cell.text.trim();

          if (text.isEmpty || text == '-') continue;

          final code = text;
          bool isGreen = false;

          String style = cell.attributes['style']?.toLowerCase() ?? '';
          final spans = cell.querySelectorAll('span, font');
          for (var s in spans) {
            style += s.attributes['style']?.toLowerCase() ?? '';
            style += s.attributes['color']?.toLowerCase() ?? '';
          }

          if (style.contains('green') ||
              style.contains('#00ff00') ||
              text.toLowerCase().contains('duty leave')) {
            isGreen = true;
          }

          if (statsMap.containsKey(code)) {
            if (isGreen) {
              statsMap[code]!.greenDutyLeaves++;
            }
          }
        }
      }
    } else {
      print('ERROR: Details table not found for Duty Leave.');
    }
  }
}
