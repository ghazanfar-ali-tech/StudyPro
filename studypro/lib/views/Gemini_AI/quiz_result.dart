import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studypro/components/appColor.dart';
import 'package:studypro/components/size_config.dart';
import 'package:studypro/providers/theme_provider.dart';
import 'package:studypro/views/Gemini_AI/quiz.dart';

class ResultScreen extends StatelessWidget {
  final int score;
  final int total;

  const ResultScreen({super.key, required this.score, required this.total});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return PopScope(
        canPop: false, 
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => GeminiQuizScreen()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background(context),
        appBar: AppBar(
          title: const Text('Quiz Results', style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.cardBackground(context),
          foregroundColor: AppColors.textPrimary(context),
          elevation: 0,
          centerTitle: true,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;
            final fontSize = isTablet ? 28.0 : 24.0;
      
            return Center(
              child: Card(
                elevation: 4,
                shadowColor: AppColors.shadow(context),
                color: AppColors.cardBackground(context),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: themeProvider.isDarkMode
                          ? [const Color(0xFF202020), const Color(0xFF303030)]
                          : [Colors.blue.shade100, Colors.blue.shade50],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.all(isTablet ? 32 : 24),
                  width: isTablet ? 500 : constraints.maxWidth * 0.9,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        score >= total * 0.7 ? Icons.check_circle : Icons.info,
                        color: score >= total * 0.7 ? AppColors.success : AppColors.warning,
                        size: isTablet ? 64 : 48,
                      ),
                       SizedBox(height: SizeConfig().scaleHeight(16, context)),
                      Text(
                        'Your Score: $score/$total',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                       SizedBox(height: SizeConfig().scaleHeight(8, context)),
                      Text(
                        score >= total * 0.7 ? 'Great job!' : 'Keep practicing!',
                        style: TextStyle(
                          fontSize: fontSize - 4,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                       SizedBox(height: SizeConfig().scaleHeight(24, context)),
                      ElevatedButton.icon(
                        onPressed: () =>  Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => GeminiQuizScreen()),
                          (route) => false, 
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Restart Quiz', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          elevation: 2,
                          shadowColor: AppColors.shadow(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}