import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

class LoginInitData {
  final Map<String, String> hiddenFields;
  final Map<String, String> cookies;
  final Uint8List? captchaImage;
  final String? errorMessage;

  LoginInitData({
    required this.hiddenFields,
    required this.cookies,
    this.captchaImage,
    this.errorMessage,
  });
}

class LoginService {
  static const String _baseUrl = 'https://kp.christuniversity.in/KnowledgePro';
  static const String _loginUrl = '$_baseUrl/StudentLogin.do';

  // Step 1: Fetch Login Page and Captcha
  Future<LoginInitData> fetchLoginPage() async {
    final client = http.Client();
    final Map<String, String> cookieJar = {};
    Uint8List? captchaBytes;
    final Map<String, String> formData = {};

    try {
      // Step A: Warm-up Request (Root URL) to initialize session/cookies
      print('DEBUG: Warming up session at $_baseUrl/ ...');
      try {
        final warmupReq = http.Request('GET', Uri.parse('$_baseUrl/'))
          ..followRedirects = false
          ..headers.addAll({
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36',
            'Accept':
                'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
            'Accept-Language': 'en-US,en;q=0.9',
            'Upgrade-Insecure-Requests': '1',
            'Sec-Fetch-Site': 'none',
            'Sec-Fetch-Mode': 'navigate',
            'Sec-Fetch-User': '?1',
            'Sec-Fetch-Dest': 'document',
            'sec-ch-ua':
                '"Google Chrome";v="137", "Chromium";v="137", "Not/A)Brand";v="24"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"Windows"',
          });

        final warmupStream = await client.send(warmupReq);
        final warmupResp = await http.Response.fromStream(warmupStream);

        if (warmupResp.headers['set-cookie'] != null) {
          print(
              'DEBUG: Warmup Set-Cookie: ${warmupResp.headers['set-cookie']}');
          cookieJar.addAll(parseCookieToMap(warmupResp.headers['set-cookie']!));
        }
      } catch (e) {
        print('DEBUG: Warmup failed (ignoring): $e');
      }

      String currentUrl = _loginUrl;
      int redirectCount = 0;
      http.Response? finalResponse;

      // Manual Redirect Loop
      while (redirectCount < 10) {
        print('DEBUG: Requesting: $currentUrl');
        final request = http.Request('GET', Uri.parse(currentUrl))
          ..followRedirects = false // CRITICAL: Handle redirects manually
          ..headers.addAll({
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36',
            'Accept':
                'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
            'Accept-Language': 'en-US,en;q=0.9',
            'Upgrade-Insecure-Requests': '1',
            'Sec-Fetch-Site': 'none',
            'Sec-Fetch-Mode': 'navigate',
            'Sec-Fetch-User': '?1',
            'Sec-Fetch-Dest': 'document',
            'sec-ch-ua':
                '"Google Chrome";v="137", "Chromium";v="137", "Not/A)Brand";v="24"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"Windows"',
            'Cookie': buildCookieHeader(cookieJar), // Send accumulated cookies
          });

        final streamedResponse = await client.send(request);
        final response = await http.Response.fromStream(streamedResponse);

        // Capture Cookies from THIS response
        String? rawCookie = response.headers['set-cookie'];
        if (rawCookie != null) {
          print('DEBUG: Set-Cookie found in ($currentUrl): $rawCookie');
          cookieJar.addAll(parseCookieToMap(rawCookie));
        }

        if (response.statusCode >= 300 && response.statusCode < 400) {
          final location = response.headers['location'];
          if (location != null) {
            currentUrl = location;
            // Handle relative redirect
            if (currentUrl.startsWith('/')) {
              currentUrl = 'https://kp.christuniversity.in$currentUrl';
            } else if (!currentUrl.startsWith('http')) {
              currentUrl = '$_baseUrl/$currentUrl'; // Fallback
            }

            print('DEBUG: Redirecting to: $currentUrl');
            redirectCount++;
            continue;
          }
        }

        finalResponse = response;
        break;
      }

      if (finalResponse == null || finalResponse.statusCode != 200) {
        throw Exception(
            'Failed to load login page properly. Final Status: ${finalResponse?.statusCode}');
      }

      print('DEBUG: Parsing login page...');
      final document = parser.parse(finalResponse.body);

      print('DEBUG: Parsed Cookies: ${cookieJar.keys.toList()}');
      if (cookieJar.containsKey('jwtCookie')) {
        print('DEBUG: ✅ jwtCookie captured successfully!');
      } else {
        print('DEBUG: ❌ jwtCookie MISSING after redirects.');
      }

      // Parse Hidden Inputs
      // Flatten input finding logic
      final inputs = document.querySelectorAll('input');
      for (var input in inputs) {
        final type = input.attributes['type']?.toLowerCase();
        final name = input.attributes['name'];
        final value = input.attributes['value'] ?? '';
        print(
            'DEBUG: Found Input: name=$name, type=$type, value=$value'); // Debug Log
        if (name != null && type == 'hidden') {
          formData[name] = value;
        }
      }

      // Fetch Captcha Image
      final captchaImg = document.getElementById('captcha_img');
      if (captchaImg != null) {
        String? src = captchaImg.attributes['src'];
        print('DEBUG: Found Captcha SRC: $src');
        if (src != null) {
          if (!src.startsWith('http')) {
            // Handle relative URL (e.g. "TempFiles//Captcha//...")
            if (src.startsWith('/')) {
              src = 'https://kp.christuniversity.in$src';
            } else {
              src = '$_baseUrl/$src';
            }
          }

          print('DEBUG: Fetching Captcha from: $src');
          // Fetch the image using the SAME cookies
          final imgResponse = await client.get(
            Uri.parse(src),
            headers: {
              'Cookie': buildCookieHeader(cookieJar),
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36',
              'Referer': _loginUrl,
            },
          );

          if (imgResponse.statusCode == 200) {
            captchaBytes = imgResponse.bodyBytes;
            print('DEBUG: Captcha fetched (${captchaBytes.length} bytes)');

            // CRITICAL: Captcha request might also rotate the session!
            if (imgResponse.headers['set-cookie'] != null) {
              print(
                  'DEBUG: Captcha response SET-COOKIE: ${imgResponse.headers['set-cookie']}');

              final newCookies =
                  parseCookieToMap(imgResponse.headers['set-cookie']!);
              cookieJar.addAll(newCookies);
            }

            // CRITICAL FIX: Populate tempCaptchaImgPath if present but empty
            // The server likely needs this to know which captcha valid to check against
            if (formData.containsKey('tempCaptchaImgPath')) {
              // Use the ORIGINAL relative path found in the HTML, not the absolute URL
              // The log showed: "TempFiles//Captcha//..."
              // We should send exactly that.
              final relativePath = src
                  .replaceFirst(
                      'https://kp.christuniversity.in/KnowledgePro/', '')
                  .replaceFirst('https://kp.christuniversity.in/', '');
              print(
                  'DEBUG: Auto-populating tempCaptchaImgPath with: $relativePath');
              formData['tempCaptchaImgPath'] = relativePath;
            }
          } else {
            print(
                'DEBUG: Failed to fetch captcha image. Status: ${imgResponse.statusCode}');
          }
        }
      } else {
        print('DEBUG: Element #captcha_img not found!');
      }

      // Serialize back to string for the provider
      final Map<String, String> cookiesData = {};
      cookiesData['Cookie'] = buildCookieHeader(cookieJar);

      return LoginInitData(
        hiddenFields: formData,
        cookies: cookiesData,
        captchaImage: captchaBytes,
      );
    } finally {
      client.close();
    }
  }

  // Step 2: Submit Credentials
  Future<Map<String, String>> login(
      String username,
      String password,
      String captcha,
      Map<String, String> cookies,
      Map<String, String> hiddenFields) async {
    final client = http.Client();
    try {
      // Step 2.1: checkDataCollectionOpen
      print('DEBUG: Step 2.1 - checkDataCollectionOpen');
      // Add standard headers
      final headers = {
        'Cookie': cookies['Cookie'] ?? '',
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': _loginUrl,
        'Origin': 'https://kp.christuniversity.in',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
        'Accept-Language': 'en-US,en;q=0.9',
        'Cache-Control': 'max-age=0',
        'Sec-Fetch-Site': 'same-origin',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-User': '?1',
        'Sec-Fetch-Dest': 'document',
        'sec-ch-ua':
            '"Not_A Brand";v="8", "Chromium";v="120", "Google Chrome";v="120"',
        'sec-ch-ua-mobile': '?0',
        'sec-ch-ua-platform': '"Windows"',
        'Upgrade-Insecure-Requests': '1',
      };

      final checkDataBody = {
        'method': 'checkDataCollectionOpen',
        'userName': username,
      };

      final checkDataReq =
          http.Request('POST', Uri.parse('$_baseUrl/StudentLoginAction.do'))
            ..headers.addAll(headers)
            ..bodyFields = checkDataBody;

      final checkDataStream = await client.send(checkDataReq);
      final checkDataResp = await http.Response.fromStream(checkDataStream);
      print(
          'DEBUG: checkDataCollectionOpen Status: ${checkDataResp.statusCode}');

      if (checkDataResp.headers['set-cookie'] != null) {
        final newCookies =
            parseCookieToMap(checkDataResp.headers['set-cookie']!);
        print('DEBUG: checkDataCollectionOpen Set-Cookie: $newCookies');
        final currentMap = parseCookieToMap(cookies['Cookie'] ?? '');
        currentMap.addAll(newCookies);
        cookies['Cookie'] = buildCookieHeader(currentMap);
        // Update headers for next request
        headers['Cookie'] = cookies['Cookie']!;
      }

      // Step 2.2: isValidUser
      print('DEBUG: Step 2.2 - isValidUser');
      final isValidUserBody = {
        'method': 'isValidUser',
        'username': username, // Note: user provided 'username' (lowercase) here
        'password': password,
        'enteredCaptcha': captcha,
        'tempCaptchaImgPath': hiddenFields['tempCaptchaImgPath'] ?? '',
        'refreshCaptcha': 'true'
      };

      final isValidReq =
          http.Request('POST', Uri.parse('$_baseUrl/StudentLoginAction.do'))
            ..headers.addAll(headers)
            ..bodyFields = isValidUserBody;

      final isValidStream = await client.send(isValidReq);
      final isValidResp = await http.Response.fromStream(isValidStream);
      print('DEBUG: isValidUser Status: ${isValidResp.statusCode}');
      print(
          'DEBUG: isValidUser Body: ${isValidResp.body}'); // Might contain specific errors!

      if (isValidResp.headers['set-cookie'] != null) {
        final newCookies = parseCookieToMap(isValidResp.headers['set-cookie']!);
        print('DEBUG: isValidUser Set-Cookie: $newCookies');
        final currentMap = parseCookieToMap(cookies['Cookie'] ?? '');
        currentMap.addAll(newCookies);
        cookies['Cookie'] = buildCookieHeader(currentMap);
        // Update headers for next request
        headers['Cookie'] = cookies['Cookie']!;
      }

      // Step 2.3: Final Login Action
      print('DEBUG: Step 2.3 - Final Login Action');
      final Map<String, String> body = Map.from(hiddenFields);
      body['method'] =
          'studentLoginAction'; // Explicitly set method (required by Struts)
      body['userName'] = username;
      body['password'] = password;
      body['enteredCaptcha'] = captcha;

      print('DEBUG: Submitting Login... User: $username, Captcha: $captcha');

      print('DEBUG: Request Origin: $_baseUrl');

      // headers are already defined and updated above
      print('DEBUG: Request Headers: $headers');
      print('DEBUG: Request Body Keys: ${body.keys.toList()}');

      final request =
          http.Request('POST', Uri.parse('$_baseUrl/StudentLoginAction.do'))
            ..headers.addAll(headers)
            ..bodyFields = body
            ..followRedirects =
                false; // CRITICAL: Stop auto-redirect to capture Set-Cookie

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      print('DEBUG: Login POST Status: ${response.statusCode}');
      print('DEBUG: Response Handled Body Length: ${response.body.length}');

      // Update cookie if changed (Critical for Session Rotation)
      // Update cookie if changed (Critical for Session Rotation)
      // Update cookie if changed (Critical for Session Rotation)
      if (response.headers['set-cookie'] != null) {
        final newCookieMap = parseCookieToMap(response.headers['set-cookie']!);
        print('DEBUG: New Session Cookie detected: $newCookieMap');

        final currentCookieString = cookies['Cookie'] ?? '';
        final currentMap = parseCookieToMap(currentCookieString);
        currentMap.addAll(newCookieMap);

        cookies['Cookie'] = buildCookieHeader(currentMap);
      }

      // Handle Redirect (Success usually 302)
      if (response.statusCode == 302 || response.statusCode == 301) {
        final location = response.headers['location'];
        print('DEBUG: Login Redirecting to: $location');

        if (location != null && location.contains('StudentLogin.do')) {
          throw Exception(
              'Login Failed: Credentials rejected (Redirected to Login)');
        }

        return {
          'Cookie': cookies['Cookie']!,
          'User-Agent': headers['User-Agent']!,
        };
      }

      // Parse the response body to check for specific error messages or successful content
      final responseDoc = parser.parse(response.body);
      final title = responseDoc.head?.querySelector('title')?.text ?? '';

      // CRITICAL: If we are still on the login page (200 OK), it's a FAILURE.
      if (title.contains('Knowledge Pro | Login') ||
          responseDoc.querySelector('input[type="password"]') != null) {
        print('DEBUG: Login POST returned Login Page (Failure).');

        // Scrape specifically for error messages
        // Common variable names / classes in Struts/JSP
        String? errorMessage;

        // Check for standard error containers
        final errorElements = responseDoc.querySelectorAll(
            'font[color="red"], span.error, .errorMessage, .errors');
        for (var el in errorElements) {
          final text = el.text.trim();
          if (text.isNotEmpty && !text.contains('*')) {
            // Ignore asterisks
            errorMessage = text;
            break;
          }
        }

        // Check inside specific IDs often used
        if (errorMessage == null) {
          errorMessage = responseDoc.getElementById('errortable')?.text.trim();
        }
        if (errorMessage == null) {
          errorMessage =
              responseDoc.getElementById('errorMessage')?.text.trim();
        }

        // Fallback: Dump text if contains "Invalid"
        if (errorMessage == null && response.body.contains('Invalid')) {
          errorMessage = "Invalid Credentials (Generic)";
        }

        print('DEBUG: Extracted Error Message: $errorMessage');

        throw Exception(
            'Login Failed: ${errorMessage ?? "Server returned login page without specific error."}');
      }

      // If no redirect and not login page, assume success (or different error page)
      // Check for dashboard indicators just in case?
      // For now, let's assume if it's NOT the login page, it's progress.

      return {
        'Cookie': cookies['Cookie']!,
        'User-Agent': headers['User-Agent']!,
      };
    } finally {
      client.close();
    }
  }

  // Helper: Parse to Map
  static Map<String, String> parseCookieToMap(String rawCookie) {
    if (rawCookie.isEmpty) return {};
    final Map<String, String> cookies = {};
    final parts = rawCookie.split(RegExp(r',(?=\s*\w+=)'));
    for (var part in parts) {
      final mainPart = part.split(';')[0].trim();
      if (mainPart.isNotEmpty) {
        final firstEq = mainPart.indexOf('=');
        if (firstEq != -1) {
          final key = mainPart.substring(0, firstEq).trim();
          final value = mainPart.substring(firstEq + 1).trim();
          final attributes = [
            'path',
            'expires',
            'domain',
            'max-age',
            'secure',
            'httponly',
            'samesite'
          ];
          if (!attributes.contains(key.toLowerCase())) {
            cookies[key] = value;
          }
        }
      }
    }
    return cookies;
  }

  // Helper: Build Header
  static String buildCookieHeader(Map<String, String> cookies) {
    return cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }
}
