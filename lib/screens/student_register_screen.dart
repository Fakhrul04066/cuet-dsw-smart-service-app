import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StudentRegisterScreen extends StatefulWidget {
  const StudentRegisterScreen({super.key});

  @override
  State<StudentRegisterScreen> createState() =>
      _StudentRegisterScreenState();
}

class _StudentRegisterScreenState extends State<StudentRegisterScreen> {
  final _studentIdController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  Future<void> _register() async {
    final studentId = _studentIdController.text.trim();
    final phone = _mobileController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (studentId.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('Please fill in all required fields.');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    if (password.length < 6) {
      _showMessage('Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _loading = true;
    });

    User? createdUser;

    try {
      final email = '$studentId@demo.cuet-dsw.local';

      // Create Firebase Authentication account first.
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      createdUser = credential.user;

      if (createdUser == null) {
        throw Exception('Could not create account.');
      }

      // Check whether this Student ID exists in the CUET registry.
      final registryDoc = await FirebaseFirestore.instance
          .collection('student_registry')
          .doc(studentId)
          .get();

      if (!registryDoc.exists) {
        await createdUser.delete();

        _showMessage(
          'Student ID is not yet listed in the CUET student registry. Ask a DSW Director to add the student record from Student Registry Management, then try again.',
        );
        return;
      }

      final studentData = registryDoc.data()!;

      if (studentData['active'] == false) {
        await createdUser.delete();

        _showMessage(
          'This student is not currently active.',
        );
        return;
      }

      // Create the actual application user profile.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(createdUser.uid)
          .set({
        'uid': createdUser.uid,
        'studentId': studentId,
        'name': studentData['name'] ?? '',
        'email': email,
        'role': 'student',
        'department': studentData['department'] ?? '',
        'batch': studentData['batch'] ?? '',
        'hall': studentData['hall'] ?? '',
        'phone': phone,
        'profileImageUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Student account created successfully. Please login.',
          ),
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showMessage(
          'An account already exists for this Student ID.',
        );
      } else if (e.code == 'weak-password') {
        _showMessage('Please use a stronger password.');
      } else if (e.code == 'network-request-failed') {
        _showMessage(
          'Network error. Please check your internet connection.',
        );
      } else {
        _showMessage(
          e.message ?? 'Registration failed.',
        );
      }
    } on FirebaseException catch (e) {
      // If Auth account was created but Firestore failed,
      // remove the incomplete Authentication account.
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {}
      }

      if (e.code == 'permission-denied') {
        _showMessage(
          'Registration permission denied. Please contact the administrator.',
        );
      } else {
        _showMessage(
          'Database error: ${e.message ?? e.code}',
        );
      }
    } catch (e) {
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {}
      }

      _showMessage(
        'Registration failed. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Registration'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'CUET Student Registration',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Only students listed in the CUET student registry can create an account.',
              ),

              const SizedBox(height: 24),

              TextField(
                controller: _studentIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Student ID',
                  hintText: 'e.g. 2104001',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(
                    Icons.badge_outlined,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number (Optional)',
                  hintText: '01XXXXXXXXX',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(
                    Icons.phone_outlined,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: _hidePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _hidePassword = !_hidePassword;
                      });
                    },
                    icon: Icon(
                      _hidePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _confirmPasswordController,
                obscureText: _hideConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _hideConfirmPassword =
                            !_hideConfirmPassword;
                      });
                    },
                    icon: Icon(
                      _hideConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              FilledButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Create Student Account',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}