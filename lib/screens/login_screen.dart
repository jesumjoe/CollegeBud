import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:attcalci/providers/attendance_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();
  bool _keepMeLoggedIn = false;

  @override
  void initState() {
    super.initState();
    // Check for saved session, if none, fetch captcha
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AttendanceProvider>();
      if (provider.captchaImage == null && !provider.isLoading) {
        provider.initLogin();
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AttendanceProvider>().login(
            _usernameController.text.trim(),
            _passwordController.text,
            _captchaController.text.trim(),
            keepLoggedIn: _keepMeLoggedIn,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  const Text(
                    "Hello 👋",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "CollegeBud",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(height: 48),

                  if (provider.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.red.withOpacity(0.1)
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isDark
                                ? Colors.red.shade900
                                : Colors.red.shade200),
                      ),
                      child: Text(
                        provider.error!,
                        style: TextStyle(
                            color: isDark
                                ? Colors.redAccent
                                : Colors.red.shade800),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  TextFormField(
                    controller: _usernameController,
                    decoration:
                        const InputDecoration(labelText: 'Username (Reg No)'),
                    style:
                        TextStyle(color: isDark ? Colors.white : Colors.black),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    style:
                        TextStyle(color: isDark ? Colors.white : Colors.black),
                    obscureText: true,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Keep Me Logged In
                  CheckboxListTile(
                    value: _keepMeLoggedIn,
                    onChanged: (val) {
                      setState(() {
                        _keepMeLoggedIn = val ?? false;
                      });
                    },
                    title: Text("Keep me logged in",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87)),
                    activeColor: const Color(0xFF2D3436),
                    checkColor: Colors.white,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: 16),

                  // CAPTCHA UI
                  if (provider.isLoading && provider.captchaImage == null)
                    const Center(child: CircularProgressIndicator())
                  else if (provider.captchaImage != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1E1E)
                            : const Color(0xFFF8F9FD),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isDark
                                ? Colors.grey.shade800
                                : const Color(0xFFE0E0E0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(provider.captchaImage!,
                                    height: 50),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => context
                                    .read<AttendanceProvider>()
                                    .initLogin(),
                                icon: const Icon(Icons.refresh),
                                tooltip: 'Refresh Captcha',
                                color: isDark ? Colors.white70 : Colors.black54,
                              )
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _captchaController,
                            decoration: const InputDecoration(
                                labelText: 'Enter Captcha'),
                            style: TextStyle(
                                color: isDark ? Colors.white : Colors.black),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ],
                      ),
                    )
                  else
                    // Fallback button
                    TextButton.icon(
                      onPressed: () =>
                          context.read<AttendanceProvider>().initLogin(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reload Captcha'),
                    ),

                  const SizedBox(height: 32),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: provider.isLoading ? null : _submit,
                      child: provider.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black))
                          : const Text('LOGIN',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
