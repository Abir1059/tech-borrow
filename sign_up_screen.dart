import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tech_borrow/services/database_helper.dart';
import 'package:tech_borrow/ui/screens/sign_in_screen.dart';
import 'package:tech_borrow/ui/screens/widgets/background_widget.dart';
import 'package:tech_borrow/ui/screens/utility/app_colors.dart';
import 'dart:math';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _studentidController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _registrationInProgress = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundWidget(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    Text(
                      'Join With Us',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your account to start borrowing',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        hintText: 'First Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) => value?.trim().isEmpty ?? true ? 'Enter first name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        hintText: 'Last Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) => value?.trim().isEmpty ?? true ? 'Enter last name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _studentidController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Student ID',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (value) => value?.trim().isEmpty ?? true ? 'Enter student ID' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _departmentController,
                      decoration: const InputDecoration(
                        hintText: 'Department',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                      validator: (value) => value?.trim().isEmpty ?? true ? 'Enter department' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) => value?.trim().isEmpty ?? true ? 'Enter email' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: 'Mobile',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (value) => value?.trim().isEmpty ?? true ? 'Enter mobile number' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        hintText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      validator: (value) => (value?.length ?? 0) < 6 ? 'Password must be at least 6 characters' : null,
                    ),
                    const SizedBox(height: 24),
                    _registrationInProgress
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _onTapSignUpButton,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Sign Up'),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          ),
                    const SizedBox(height: 32),
                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium,
                          text: "Have an account? ",
                          children: [
                            TextSpan(
                              text: 'Sign in',
                              style: const TextStyle(
                                color: Appcolors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: TapGestureRecognizer()..onTap = _onTapSignInButton,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTapSignUpButton() {
    if (_formKey.currentState!.validate()) {
      _registerUser();
    }
  }

  Future<void> _registerUser() async {
    setState(() {
      _registrationInProgress = true;
    });

    try {
      final dbHelper = DatabaseHelper();
      final String email = _emailController.text.trim();
      final String password = _passwordController.text;
      final String uid = DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(1000).toString();

      await dbHelper.insertUser({
        'uid': uid,
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'studentId': _studentidController.text.trim(),
        'department': _departmentController.text.trim(),
        'email': email,
        'mobile': _mobileController.text.trim(),
        'password': password,
        'createdAt': DateTime.now().toIso8601String(),
      });

      setState(() {
        _registrationInProgress = false;
      });

      if (mounted) {
        _clearTextFields();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _registrationInProgress = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.toString()}'), backgroundColor: Appcolors.error),
        );
      }
    }
  }

  void _clearTextFields() {
    _emailController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _mobileController.clear();
    _studentidController.clear();
    _departmentController.clear();
    _passwordController.clear();
  }

  void _onTapSignInButton() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _studentidController.dispose();
    _departmentController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
