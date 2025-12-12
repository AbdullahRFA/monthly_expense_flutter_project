import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart'; // Import our repository
import 'signup_screen.dart';
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Controllers capture what the user types
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // This key is used to "validate" the form (check for empty fields)
  final _formKey = GlobalKey<FormState>();

  // To show a loading spinner when logging in
  bool _isLoading = false;

  @override
  void dispose() {
    // ALWAYS dispose controllers to free up memory when screen is closed
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // THE CORE LOGIC FUNCTION
  Future<void> _login() async {
    // 1. Validate inputs (Are they empty?)
    if (!_formKey.currentState!.validate()) return;

    // 2. Set loading state (UI updates to show spinner)
    setState(() => _isLoading = true);

    try {
      // 3. CALL THE REPOSITORY
      // ref.read() is how we access the provider.
      // We don't say "new AuthRepository()". We ask Riverpod for the existing one.
      await ref.read(authRepositoryProvider).loginWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      // If successful, the AuthGate (which we build next) will auto-switch to Home.

    } catch (e) {
      // 4. Handle Errors (e.g., Wrong password)
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))),
      );
    } finally {
      // 5. Stop loading spinner regardless of success/failure
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Monthly Expense",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  // Validator: Returns string if error, null if okay
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter email';
                    if (!value.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true, // Hide password
                  validator: (value) {
                    if (value == null || value.length < 6) return 'Password too short';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  width: double.infinity, // Stretch button
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login, // Disable if loading
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Login"),
                  ),
                ),

                // Sign Up Link (We will implement this next)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignUpScreen()),
                    );
                  },
                  child: const Text("Don't have an account? Sign Up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}