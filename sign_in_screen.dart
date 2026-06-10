import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tech_borrow/services/database_helper.dart';
import 'package:tech_borrow/services/auth_service.dart';
import 'package:tech_borrow/ui/screens/auth/email_verification_screen.dart';
import 'package:tech_borrow/ui/screens/home_page.dart';
import 'package:tech_borrow/ui/screens/widgets/background_widget.dart';
import 'package:tech_borrow/ui/screens/widgets/sign_up_screen.dart';
import 'package:tech_borrow/ui/screens/utility/app_colors.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _signInApiInProgress = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundWidget(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to your account to continue',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 36),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) => value?.trim().isEmpty ?? true ? 'Enter email address' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Enter password' : null,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _onTapForgotPasswordButton,
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _signInApiInProgress
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _onTapSignInButton,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Sign In'),
                                  SizedBox(width: 8),
                                  Icon(Icons.login_rounded, size: 20),
                                ],
                              ),
                            ),
                      const SizedBox(height: 32),
                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium,
                            text: "Don't have an account? ",
                            children: [
                              TextSpan(
                                text: 'Sign up',
                                style: const TextStyle(
                                  color: Appcolors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                                recognizer: TapGestureRecognizer()..onTap = _onTapSignUpButton,
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
      ),
    );
  }

  void _onTapSignInButton() {
    if (_formKey.currentState!.validate()) {
      _signIn();
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _signInApiInProgress = true;
    });

    try {
      final dbHelper = DatabaseHelper();
      final String email = _emailController.text.trim();
      final String password = _passwordController.text;

      final user = await dbHelper.getUser(email, password);

      if (user != null) {
        await AuthService.login(user['uid'], user['email']);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid email or password')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _signInApiInProgress = false;
      });
    }
  }

  void _onTapSignUpButton() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );
  }

  void _onTapForgotPasswordButton() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EmailVerificationScreen()),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
