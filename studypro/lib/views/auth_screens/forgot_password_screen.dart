import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studypro/components/appColor.dart';
import 'package:studypro/providers/theme_provider.dart' show ThemeProvider;
import 'package:studypro/views/widgets/round_button.dart';
import 'package:studypro/views/widgets/toast_message.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Forgot Password'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration:  BoxDecoration(
          gradient: LinearGradient(
            colors: themeProvider.isDarkMode ?  [Color.fromARGB(255, 32, 32, 32), Color.fromARGB(255, 48, 48, 48)] : [Color(0xFF6DD5FA), Color(0xFF2980B9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground(context,),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: themeProvider.isDarkMode ? const Color.fromARGB(135, 102, 101, 101) : (Colors.grey[300] ?? Colors.grey),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text(
                    'Reset Your Password',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color:  themeProvider.isDarkMode ? AppColors.primaryLight : Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 10),
                   Text(
                    'Enter your email and we will send you a password reset link.',
                    style: TextStyle(
                      fontSize: 14,
                      color: themeProvider.isDarkMode ? AppColors.primaryLight : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: 'Enter your email',
                      prefixIcon: const Icon(Icons.email_outlined,color: AppColors.iconPrimary,),
                      filled: true,
                      fillColor: AppColors.cardBackground(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  RoundButton(
                  
                    title: 'Send Reset Link',
                      gradient:  LinearGradient(
              colors: themeProvider.isDarkMode ? [const Color.fromARGB(255, 32, 32, 32), const Color.fromARGB(255, 48, 48, 48)]: [Colors.blueAccent, Colors.black],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
          ),
                    ontap: ()async {
                      final email = emailController.text.trim();
                      if (email.isEmpty) {
                        Utils.toastMessage("Please enter your email.");
                        return;
                      }
                     await auth.sendPasswordResetEmail(email: email).then((value) {
                        Utils.toastMessage(
                            'Password reset email sent! Please check your inbox.');
                      }).onError((error, stackTrace) {
                        Utils.toastMessage(error.toString());
                      });
                    },
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