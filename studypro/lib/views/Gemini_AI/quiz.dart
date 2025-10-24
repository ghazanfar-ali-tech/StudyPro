import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:studypro/components/appColor.dart';
import 'package:studypro/components/size_config.dart';
import 'package:studypro/providers/theme_provider.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as google_ai;
import 'package:studypro/views/Gemini_AI/constants.dart';
import 'package:studypro/views/Gemini_AI/quiz_result.dart';
import 'package:studypro/views/main_page_screen.dart';


class GeminiQuizScreen extends StatefulWidget {
  const GeminiQuizScreen({super.key});

  @override
  _GeminiQuizScreenState createState() => _GeminiQuizScreenState();
}

class _GeminiQuizScreenState extends State<GeminiQuizScreen> {
  final _promptController = TextEditingController();
  final _numQuestionsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _promptController.dispose();
    _numQuestionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return PopScope(
          canPop: false, 
    onPopInvokedWithResult: (_, __) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => MainPageScreen()),
        (route) => false,
      );
    },
      child: Scaffold(
        backgroundColor: AppColors.background(context),
        appBar: AppBar(
          title: const Text('Quiz Generator', style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.cardBackground(context),
          foregroundColor: AppColors.textPrimary(context),
          elevation: 0,
          centerTitle: true,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;
            final padding = isTablet ? 32.0 : 16.0;
            final fontSize = isTablet ? 18.0 : 16.0;
      
            return SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
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
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Your Quiz',
                            style: TextStyle(
                              fontSize: fontSize + 2,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                           SizedBox(height: SizeConfig().scaleHeight(16, context)),
                          TextField(
                            controller: _promptController,
                            decoration: InputDecoration(
                              labelText: 'Quiz topic or content',
                              labelStyle: TextStyle(color: AppColors.textSecondary(context)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.border(context)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              
                              filled: true,
                              fillColor: AppColors.cardBackground(context),
                              prefixIcon: Icon(Icons.edit, color: AppColors.iconPrimary),
                            ),
                            style: TextStyle(fontSize: fontSize, color: AppColors.textPrimary(context)),
                            maxLines: 3,
                          ),
                           SizedBox(height: SizeConfig().scaleHeight(16, context)),
                          TextField(
                            controller: _numQuestionsController,
                            decoration: InputDecoration(
                              labelText: 'Number of questions',
                              labelStyle: TextStyle(color: AppColors.textSecondary(context)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.border(context)),
                              ),
                              filled: true,
                              fillColor: AppColors.cardBackground(context),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              
                              prefixIcon: Icon(Icons.format_list_numbered, color: AppColors.iconPrimary),
                            ),
                            
                            style: TextStyle(fontSize: fontSize, color: AppColors.textPrimary(context)),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                  ),
                   SizedBox(height: SizeConfig().scaleHeight(24, context)),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _generateQuiz,
                      icon: _isLoading
                          ?  SizedBox(
                              width: SizeConfig().scaleWidth(24, context),
                              height: SizeConfig().scaleHeight(24, context),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.quiz),
                      label: Text(_isLoading ? 'Generating...' : 'Generate Quiz', style: const TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        elevation: 2,
                        shadowColor: AppColors.shadow(context),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _generateQuiz() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final model = google_ai.GenerativeModel(model: 'gemini-1.5-flash', apiKey: geminiApiKey);
    final promptText = _promptController.text.trim();
    final numQuestions = int.tryParse(_numQuestionsController.text) ?? 5;

    if (promptText.isEmpty) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please enter a quiz topic or content', style: TextStyle(color: AppColors.textPrimary(context))),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    final prompt = '''
Create $numQuestions MCQs based on: "$promptText". 
Each question needs 4 options, 1 correct. 
Use JSON format:
[
  {
    "question": "Question text",
    "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
    "correct": "Option 1"
  }
]
Keep responses concise.
''';

    const maxRetries = 3;
    int retryCount = 0;
    const baseDelay = Duration(seconds: 2);

    while (retryCount < maxRetries) {
      try {
        final response = await model.generateContent([google_ai.Content.text(prompt)]);
        if (response.text == null) {
          throw Exception('Empty response from API');
        }
        final jsonString = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
        final mcqs = jsonDecode(jsonString) as List;
        if (mcqs.isEmpty) {
          throw Exception('No questions generated');
        }
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizScreen(mcqs: mcqs),
            ),
          );
        }
        break;
      } catch (e) {
        retryCount++;
        if (retryCount == maxRetries) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error generating quiz: $e', style: TextStyle(color: AppColors.textPrimary(context))),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          });
          break;
        }
        await Future.delayed(baseDelay * (1 << retryCount));
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

class QuizScreen extends StatefulWidget {
  final List<dynamic> mcqs;

  const QuizScreen({super.key, required this.mcqs});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestion = 0;
  int _score = 0;
  List<String?> _userAnswers = [];

  @override
  void initState() {
    super.initState();
    _userAnswers = List.filled(widget.mcqs.length, null);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final mcq = widget.mcqs[_currentQuestion];

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Quiz (${_currentQuestion + 1}/${widget.mcqs.length})', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.cardBackground(context),
        foregroundColor: AppColors.textPrimary(context),
        elevation: 0,
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 600;
          final padding = isTablet ? 32.0 : 16.0;
          final fontSize = isTablet ? 20.0 : 18.0;

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
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
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question ${_currentQuestion + 1}: ${mcq['question']}',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                     SizedBox(height: SizeConfig().scaleHeight(16, context)),
                    ...mcq['options'].asMap().entries.map((entry) {
                      final option = entry.value;
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border(context)),
                          borderRadius: BorderRadius.circular(8),
                          color: _userAnswers[_currentQuestion] == option
                              ? themeProvider.isDarkMode ? const Color.fromARGB(255, 49, 49, 49): const Color.fromARGB(255, 152, 212, 197)
                              : AppColors.cardBackground(context),
                        ),
                        child: RadioListTile<String>(
                          title: Text(
                            option,
                            style: TextStyle(
                              fontSize: fontSize - 2,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          value: option,
                          groupValue: _userAnswers[_currentQuestion],
                          onChanged: (value) {
                            if (mounted) {
                              setState(() {
                                _userAnswers[_currentQuestion] = value;
                              });
                            }
                          },
                          activeColor: AppColors.primary,
                        ),
                      );
                    }).toList(),
                     SizedBox(height: SizeConfig().scaleHeight(24, context)),
                    Center(
                      child: ElevatedButton(
                        onPressed: _userAnswers[_currentQuestion] == null
                            ? null
                            : () {
                                if (_userAnswers[_currentQuestion] == mcq['correct']) {
                                  _score++;
                                }
                                if (_currentQuestion < widget.mcqs.length - 1) {
                                  if (mounted) {
                                    setState(() {
                                      _currentQuestion++;
                                    });
                                  }
                                } else {
                                  if (mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ResultScreen(
                                          score: _score,
                                          total: widget.mcqs.length,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                        child: Text(
                          _currentQuestion < widget.mcqs.length - 1 ? 'Next' : 'Finish',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          elevation: 2,
                          shadowColor: AppColors.shadow(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

