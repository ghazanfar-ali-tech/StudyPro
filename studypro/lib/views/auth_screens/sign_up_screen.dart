import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:studypro/components/appColor.dart';
import 'package:studypro/providers/auth_providers/signup_providers.dart';
import 'package:studypro/providers/theme_provider.dart';
import 'package:studypro/routes/app_routes.dart';
import 'package:studypro/views/widgets/round_button.dart';
import 'package:studypro/views/widgets/toast_message.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _countryFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    print('SignUpScreen initialized');
    //=> debug focus changes
    _usernameFocus.addListener(() {
      print('Username field focus: ${_usernameFocus.hasFocus}');
    });
    _emailFocus.addListener(() {
      print('Email field focus: ${_emailFocus.hasFocus}');
    });
    _passwordFocus.addListener(() {
      print('Password field focus: ${_passwordFocus.hasFocus}');
    });
    _countryFocus.addListener(() {
      print('Country field focus: ${_countryFocus.hasFocus}');
    });
  }

  @override
  void dispose() {
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _countryFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signUpProvider = Provider.of<SignUpProvider>(context);
    var screenHeight = MediaQuery.of(context).size.height;
    print('SignUpScreen rebuilt');
    final themeProvider = Provider.of<ThemeProvider>(context);

    return GestureDetector(
      onTap: () {
        print('Tapped outside text fields');
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        body: SizedBox(
          height: screenHeight,
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      width: MediaQuery.sizeOf(context).width,
                      height: MediaQuery.sizeOf(context).height * 0.5,
                      decoration:  BoxDecoration(
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20)),
                                       gradient:  LinearGradient(
  colors: themeProvider.isDarkMode
      ? [Color.fromARGB(255, 32, 32, 32), Color.fromARGB(255, 48, 48, 48)]
      : [Color(0xFF6DD5FA), Color.fromARGB(255, 15, 68, 104)], 
  begin: Alignment.topRight,
  end: Alignment.bottomLeft,
)
                      ),
                      child: Center(
                        child: SizedBox(
                          width: MediaQuery.sizeOf(context).width * 0.7,
                          height: MediaQuery.sizeOf(context).height * 0.7,
                          child: Lottie.network(
                            'https://lottie.host/2b86d691-624a-4961-8c51-048ec0c90603/9tT385zTnP.json',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 325,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding:  EdgeInsets.symmetric(horizontal: 20.0),
                        decoration:  BoxDecoration(
                          color: AppColors.cardBackground(context),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(23),
                            topRight: Radius.circular(23),
                          ),
                        ),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                                    _buildTextField(
                                      context: context,
                                      controller: signUpProvider.usernameController,
                                      focusNode: _usernameFocus,
                                      hintText: 'Username',
                                      icon: Icons.person_outline,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Enter username';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    _buildTextField(
                                      context: context,
                                      controller: signUpProvider.emailController,
                                      focusNode: _emailFocus,
                                      hintText: 'Email',
                                      icon: Icons.email_outlined,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Enter email';
                                        }
                                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                          return 'Enter a valid email address';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    _buildTextField(
                                      context: context,
                                      controller: signUpProvider.passwordController,
                                      focusNode: _passwordFocus,
                                      hintText: 'Password',
                                      icon: Icons.lock_clock_outlined,
                                      obscureText: signUpProvider.obscurePassword,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Enter password';
                                        }
                                        if (value.length < 6) {
                                          return 'Password must be at least 6 characters';
                                        }
                                        return null;
                                      },
                                      togglePasswordVisibility: () {
                                        print('Toggling password visibility');
                                        signUpProvider.togglePasswordVisibility();
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    _buildTextField(
                                      context: context,
                                      controller: signUpProvider.countryController,
                                      focusNode: _countryFocus,
                                      hintText: 'Country',
                                      icon: Icons.flag_outlined,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Enter country';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    _buildRoleRadioButtons(
                                      context: context,
                                      groupValue: signUpProvider.selectedRole,
                                      onChanged: (String? value) {
                                        signUpProvider.setRole(value);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              RoundButton(
                                title: 'Sign up',
                                   gradient: LinearGradient(
            colors: themeProvider.isDarkMode
                ? [const Color.fromARGB(255, 32, 32, 32), const Color.fromARGB(255, 48, 48, 48)]
                : [Colors.blue, Colors.black],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
                                loading: signUpProvider.loading,
                                ontap: () {
                                  print('Sign up button tapped');
                                  if (_formKey.currentState!.validate()) {
                                    if (signUpProvider.selectedRole == null) {
                                      Utils.toastMessage('Please select a role');
                                      return;
                                    }
                                    signUpProvider.signUp(context);
                                  }
                                },
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("Already have an account?"),
                                  TextButton(
                                    onPressed: () {
                                      print('Login button tapped');
                                      FocusScope.of(context).unfocus();
                                      Navigator.pushNamed(context, AppRoutes.login);
                                    },
                                    child: const Text(
                                      'Login',
                                      style: TextStyle(
                                        color: AppColors.iconPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
    VoidCallback? togglePasswordVisibility,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      onTap: () {
        print('Tapped $hintText field');
        FocusScope.of(context).requestFocus(focusNode);
      },
      decoration: InputDecoration(
        prefixIcon: Icon(icon,color: AppColors.iconPrimary),
        hintText: hintText,
        filled: true,
        fillColor: AppColors.cardBackground(context),
        contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
        suffixIcon: hintText == 'Password'
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.iconPrimary,
                ),
                onPressed: togglePasswordVisibility,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: const BorderSide(color: Colors.blue),
        ),
      ),
      style: TextStyle(color: AppColors.textPrimary(context)),
      validator: validator,
    );
  }

  Widget _buildRoleRadioButtons({
    required BuildContext context,
    required String? groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Role',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Student'),
                value: 'Student',
                groupValue: groupValue,
                onChanged: onChanged,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Teacher'),
                value: 'Teacher',
                groupValue: groupValue,
                onChanged: onChanged,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }
}