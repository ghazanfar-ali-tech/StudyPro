import 'package:flutter/material.dart';

class RoundButton extends StatelessWidget {
  final String title;
  final VoidCallback ontap;
  final bool loading;
  final Gradient? gradient;
  final Color? color;  

  const RoundButton({
    super.key,
    required this.title,
    required this.ontap,
    this.loading = false,
    this.gradient,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      height: 50,
      decoration: BoxDecoration(
        gradient: gradient ?? (color != null ? LinearGradient(colors: [color!, color!]) : null),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, backgroundColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: loading ? null : ontap,
        child: loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Center(child: Text(title, style: const TextStyle(color: Colors.white,fontSize: 19))),
      ),
    );
  }
}
