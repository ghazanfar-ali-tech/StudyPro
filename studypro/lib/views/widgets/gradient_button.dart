
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studypro/providers/theme_provider.dart';

class GradientButton extends StatelessWidget {
  final String title;
  final VoidCallback ontap;
  final bool loading;
  final Color? textColor;

  const GradientButton({
    required this.title,
    required this.ontap,
    this.loading = false,
    this.textColor = Colors.white,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      child: ElevatedButton(
      
        onPressed: loading ? null : ontap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, 
          shadowColor: Colors.black.withOpacity(0.5), 
          elevation: 5, 
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          padding: EdgeInsets.zero, 
        ),
        child: Ink(
          decoration: BoxDecoration(
             gradient: LinearGradient(
            colors: themeProvider.isDarkMode
                ? [const Color.fromARGB(255, 32, 32, 32), const Color.fromARGB(255, 48, 48, 48)]
                : [Colors.blue, Colors.black],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
            borderRadius: BorderRadius.circular(30.0),
            
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300, minHeight: 50),
            alignment: Alignment.center,
            child: loading
                ? const CircularProgressIndicator(color: Colors.white,) 
                : Text(
                    title,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 19), 
                  ),
          ),
        ),
      ),
    );
  }


  
}
