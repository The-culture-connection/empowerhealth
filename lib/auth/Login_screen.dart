import 'package:flutter/material.dart';
import '../app_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/loginscreen.jpeg', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.4)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Welcome back', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(labelText: 'Email'),
                            validator: (v) => (v == null || v.isEmpty) ? 'Enter your email' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _password,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'Password'),
                            validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                Navigator.pushReplacementNamed(context, Routes.main);
                              }
                            },
                            child: const Text('Log In'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, Routes.signup),
                            child: const Text("Don't have an account? Sign Up"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
