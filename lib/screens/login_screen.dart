import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';

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
      context.read<AttendanceProvider>().checkSession();
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

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.school, size: 80, color: Color(0xFF003366)),
                  const SizedBox(height: 24),
                  const Text(
                    'Christ University\nTrue Attendance',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 48),

                  if (provider.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        provider.error!,
                        style: TextStyle(color: Colors.red.shade800),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  TextFormField(
                    controller: _usernameController,
                    decoration:
                        const InputDecoration(labelText: 'Username (Reg No)'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),

                  // CAPTCHA UI
                  if (provider.isLoading && provider.captchaImage == null)
                    const Center(child: CircularProgressIndicator())
                  else if (provider.captchaImage != null)
                    Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey)),
                              child: Image.memory(provider.captchaImage!,
                                  height: 50),
                            ),
                            IconButton(
                              onPressed: () => context
                                  .read<AttendanceProvider>()
                                  .initLogin(),
                              icon: const Icon(Icons.refresh),
                              tooltip: 'Refresh Captcha',
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _captchaController,
                          decoration:
                              const InputDecoration(labelText: 'Enter Captcha'),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Required'
                              : null,
                        ),
                      ],
                    )
                  else
                    // Fallback button if captcha failed to load
                    TextButton.icon(
                      onPressed: () =>
                          context.read<AttendanceProvider>().initLogin(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reload Captcha'),
                    ),

                  const SizedBox(height: 16),
                  CheckboxListTile(
                    value: _keepMeLoggedIn,
                    onChanged: (val) {
                      setState(() {
                        _keepMeLoggedIn = val ?? false;
                      });
                    },
                    title: const Text("Keep me logged in"),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: provider.isLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: provider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('LOGIN'),
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
