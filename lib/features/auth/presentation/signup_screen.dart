import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Call Repository
      await ref.read(authRepositoryProvider).signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // 2. Wait a moment to ensure AuthGate settles (prevents glitches)
      await Future.delayed(const Duration(milliseconds: 200));

      if (!mounted) return;

      // 3. Show Success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created! Please Login."),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // 4. Force go back to Login
      // We check if we can pop to avoid errors if AuthGate already closed us
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

    } catch (e) {
      if (!mounted) return;
      // SHOW THE REAL ERROR
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString().replaceAll("Exception: ", "")}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
                validator: (v) => !v!.contains('@') ? 'Invalid email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()),
                obscureText: true,
                validator: (v) => v!.length < 6 ? 'Password too short' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  child: _isLoading ? const CircularProgressIndicator() : const Text("Sign Up"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}