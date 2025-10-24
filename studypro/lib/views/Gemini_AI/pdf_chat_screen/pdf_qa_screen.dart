import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:studypro/components/appColor.dart';
import 'package:studypro/components/size_config.dart';
import 'package:studypro/providers/theme_provider.dart';
import 'package:studypro/services/gemini_service.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfQAScreen extends StatefulWidget {
  const PdfQAScreen({super.key});

  @override
  State<PdfQAScreen> createState() => _PdfQAScreenState();
}

class _PdfQAScreenState extends State<PdfQAScreen> {
  String? _extractedText;
  String? _geminiAnswer;
  final TextEditingController _questionController = TextEditingController();
  bool _isLoading = false;
  bool isExpanded = false; 
  final GeminiService _geminiService = GeminiService();

  Future<void> _pickAndExtractPDF() async {
    setState(() => _isLoading = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes());
        final PdfTextExtractor extractor = PdfTextExtractor(document);
        final text = extractor.extractText();
        document.dispose();
        setState(() {
          _extractedText = text;
          _isLoading = false;
        });
        _showSnackBar('PDF uploaded successfully', AppColors.success);
      } else {
        setState(() => _isLoading = false);
        _showSnackBar('No PDF selected', AppColors.warning);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _extractedText = null;
        _geminiAnswer = null;
      });
      _showSnackBar('Error extracting PDF: $e', AppColors.error);
    }
  }

  Future<void> _askQuestion() async {
    if (_extractedText == null || _questionController.text.isEmpty) {
      _showSnackBar('Please upload a PDF and enter a question', AppColors.warning);
      return;
    }
    setState(() => _isLoading = true);
    final prompt =
        'Using the following content from a PDF: \n$_extractedText\nAnswer this question: ${_questionController.text}';
    try {
      final answer = await _geminiService.callGeminiAPI(prompt);
      setState(() {
        _geminiAnswer = answer;
        _isLoading = false;
      });
      _showSnackBar('Answer received', AppColors.success);
    } catch (e) {
      setState(() {
        _geminiAnswer = 'Error: $e';
        _isLoading = false;
      });
      _showSnackBar('Failed to get answer from AI', AppColors.error);
    }
  }

  void _clearPDF() {
    setState(() {
      _extractedText = null;
      _geminiAnswer = null;
      _questionController.clear();
      isExpanded = false;
    });
    _showSnackBar('PDF and answers cleared', AppColors.info);
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback onPressed,
    required IconData icon,
    bool isSecondary = false,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      width: double.infinity,
      height: SizeConfig().scaleHeight(56, context),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSecondary
              ? (themeProvider.isDarkMode
                  ? [const Color(0xFF374151), const Color(0xFF1F2937)]
                  : [const Color(0xFFF3F4F6), const Color(0xFFE5E7EB)])
              : [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSecondary ? AppColors.textPrimary(context) : Colors.white,
                size: 24,
              ),
               SizedBox(width: SizeConfig().scaleWidth(8, context)),
              Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSecondary ? AppColors.textPrimary(context) : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentCard({
    required String title,
    required String content,
    required IconData icon,
  }) {

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
        ),
        iconColor: AppColors.iconPrimary,
        collapsedIconColor: AppColors.iconSecondary(context),
        backgroundColor: AppColors.cardBackground(context),
        collapsedBackgroundColor: AppColors.cardBackground(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.border(context)),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.border(context)),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(context),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              border: Border(top: BorderSide(color: AppColors.border(context))),
            ),
            child: SingleChildScrollView(
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
  
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.cardBackground(context),
        title: Text(
          'PDF Q&A',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border(context)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow(context),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                     SizedBox(height: SizeConfig().scaleHeight(12, context)),
                    Text(
                      'Processing...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth > 600;
                final padding = isTablet ? 24.0 : 16.0;
                return SingleChildScrollView(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildGradientButton(
                              text: _extractedText == null ? 'Upload PDF' : 'Change PDF',
                              onPressed: _pickAndExtractPDF,
                              icon: Icons.file_upload,
                            ),
                          ),
                          if (_extractedText != null) ...[
                             SizedBox(width: SizeConfig().scaleWidth(12, context)),
                            Expanded(
                              child: _buildGradientButton(
                                text: 'Clear PDF',
                                onPressed: _clearPDF,
                                icon: Icons.delete,
                                isSecondary: true,
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: padding),
                      if (_extractedText != null)
                        _buildContentCard(
                          title: 'Extracted PDF Content',
                          content: _extractedText!,
                          icon: Icons.description,
                        ),
                      if (_extractedText != null) SizedBox(height: padding),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border(context)),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadow(context),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _questionController,
                          maxLines: 3,
                          style: TextStyle(
                            color: AppColors.textPrimary(context),
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Ask a question about the PDF',
                            labelStyle: TextStyle(
                              color: AppColors.textSecondary(context),
                            ),
                            filled: true,
                            fillColor: AppColors.cardBackground(context),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
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
                            prefixIcon: Icon(
                              Icons.question_answer,
                              color: AppColors.iconSecondary(context),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: padding),
                      _buildGradientButton(
                        text: 'Get Answer',
                        onPressed: _askQuestion,
                        icon: Icons.psychology,
                      ),
                      SizedBox(height: padding),

                      if (_geminiAnswer != null)
                        _buildContentCard(
                          title: 'AI Answer',
                          content: _geminiAnswer!,
                          icon: Icons.auto_awesome,
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }
}