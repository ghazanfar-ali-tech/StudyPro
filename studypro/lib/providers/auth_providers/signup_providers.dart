import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:studypro/routes/app_routes.dart';
import 'package:studypro/views/widgets/toast_message.dart';

class SignUpProvider with ChangeNotifier {
  bool _loading = false;
  bool _obscurePassword = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  String? _selectedRole; 
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool get loading => _loading;
  bool get obscurePassword => _obscurePassword;
  TextEditingController get emailController => _emailController;
  TextEditingController get passwordController => _passwordController;
  TextEditingController get usernameController => _usernameController;
  TextEditingController get countryController => _countryController;
  String? get selectedRole => _selectedRole;

  void setRole(String? role) {
    _selectedRole = role;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  Future<void> signUp(BuildContext context) async {
    _loading = true;
    notifyListeners();

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'country': _countryController.text.trim(),
        'role': _selectedRole ?? 'Student',
        'password': _passwordController.text.trim(),
        'uid': userCredential.user!.uid,
      });
      Utils.toastMessage('Account created successfully!');
      _usernameController.clear();
      _emailController.clear();
      _countryController.clear();
      _passwordController.clear();
      _selectedRole = null; // => clear role
      Navigator.pushNamed(context, AppRoutes.login);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already registered.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format.';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak.';
          break;
        default:
          errorMessage = 'Error: ${e.message}';
      }
      debugPrint(errorMessage);
      Utils.toastMessage(errorMessage);
    } catch (e) {
      debugPrint(e.toString());
      Utils.toastMessage('An unexpected error occurred: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _countryController.dispose();
    super.dispose();
  }
}