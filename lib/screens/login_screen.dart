import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/student_auth_mapper.dart';
import 'auth_gate.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  String _selectedRole = 'student';

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _title {
    switch (_selectedRole) {
      case 'dsw_officer':
        return 'DSW Officer Login';
      case 'dsw_director':
        return 'DSW Director Login';
      default:
        return 'Student Login';
    }
  }

  String get _subtitle {
    switch (_selectedRole) {
      case 'dsw_officer':
        return 'Manage student welfare services';
      case 'dsw_director':
        return 'Review and approve institutional actions';
      default:
        return 'Access your student welfare services';
    }
  }

  String get _identifierLabel {
    switch (_selectedRole) {
      case 'dsw_officer':
        return 'Email';
      case 'dsw_director':
        return 'Email';
      default:
        return 'Student ID';
    }
  }

  String get _identifierHint {
    switch (_selectedRole) {
      case 'dsw_officer':
        return 'officer1@demo.com';
      case 'dsw_director':
        return 'director@demo.com';
      default:
        return 'e.g. 2104001';
    }
  }

  TextInputType get _keyboardType {
    switch (_selectedRole) {
      case 'dsw_officer':
        return TextInputType.emailAddress;
      case 'dsw_director':
        return TextInputType.emailAddress;
      default:
        return TextInputType.number;
    }
  }

  Future<void> _handleLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      _showMessage(
        'Please enter your ${_identifierLabel.toLowerCase()} and password.',
      );
      return;
    }

    if (_selectedRole == 'student') {
      if (!StudentAuthMapper.isValidStudentId(identifier)) {
        _showMessage('Please enter a valid Student ID (for example 2104001).');
        return;
      }
    } else if (!StudentAuthMapper.isEmailLike(identifier)) {
      _showMessage('Please enter a valid email address.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await AuthService.instance.signInWithSelectedRole(
        selectedRole: _selectedRole,
        loginIdentifier: identifier,
        password: password,
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );

      _showMessage('Welcome, ${user.name.isNotEmpty ? user.name : user.email}');
    } on FirebaseAuthException catch (error) {
      final message = _friendlyAuthError(error.code);
      _showMessage(message);
    } on StateError catch (error) {
      _showMessage(error.message);
    } on FormatException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage(
        'Unable to sign in. Please check your connection and try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _friendlyAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-not-found':
        return 'No account found for that email or student ID.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _onRoleChanged(String? value) {
    if (value == null) {
      return;
    }

    setState(() {
      _selectedRole = value;
      _identifierController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(_subtitle, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 20),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'student',
                        label: Text('Student'),
                      ),
                      ButtonSegment<String>(
                        value: 'dsw_officer',
                        label: Text('DSW Officer'),
                      ),
                      ButtonSegment<String>(
                        value: 'dsw_director',
                        label: Text('DSW Director'),
                      ),
                    ],
                    selected: {_selectedRole},
                    onSelectionChanged: (selection) =>
                        _onRoleChanged(selection.first),
                    showSelectedIcon: false,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _identifierController,
                    decoration: InputDecoration(
                      labelText: _identifierLabel,
                      hintText: _identifierHint,
                      prefixIcon: Icon(
                        _selectedRole == 'student'
                            ? Icons.person_outline_rounded
                            : Icons.email_outlined,
                      ),
                    ),
                    keyboardType: _keyboardType,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                      ),
                      const Text('Remember me'),
                      const Spacer(),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Forgot Password?'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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
