
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studypro/routes/app_routes.dart';
import 'package:studypro/views/widgets/toast_message.dart';

class LoginProvider with ChangeNotifier {
  bool _loading = false;
  bool _obscurePassword = true;
  String? _userRole;
  String? _userId;
  String? _email; 
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool get loading => _loading;
  bool get obscurePassword => _obscurePassword;
  String? get userRole => _userRole;
  String? get userId => _userId;
  String? get email => _email; 
  TextEditingController get emailController => _emailController;
  TextEditingController get passwordController => _passwordController;


  LoginProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _userRole = prefs.getString('userRole');
    _userId = prefs.getString('userId');
    _email = prefs.getString('email');
    print('Loaded from prefs - Role: $_userRole, UserId: $_userId, Email: $_email');
    notifyListeners();
  }

  Future<void> _saveToPrefs(String role, String userId, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userRole', role);
    await prefs.setString('userId', userId);
    await prefs.setString('email', email); 
    print('Saved to prefs - Role: $role, UserId: $userId, Email: $email');
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  Future<void> login(BuildContext context) async {
    _loading = true;
    notifyListeners();

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final user = userCredential.user!;
      _userId = user.uid;
      _email = user.email; 
 
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      _userRole = userDoc.data()?['role'] ?? 'Student';
  
      await _saveToPrefs(_userRole!, _userId!, _email!);
      Utils.toastMessage('Welcome, $_userRole: ${_email}');
      _emailController.clear();
      _passwordController.clear();
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.mainPage, (route) => false,);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format.';
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


  Future<void> logout(BuildContext context) async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userRole');
    await prefs.remove('userId');
    await prefs.remove('email'); 
    _userRole = null;
    _userId = null;
    _email = null; 
    _emailController.clear();
    _passwordController.clear();
    notifyListeners();
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}