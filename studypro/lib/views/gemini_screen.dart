import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studypro/components/appColor.dart';
import 'package:studypro/components/size_config.dart';
import 'package:studypro/providers/theme_provider.dart';
import 'package:studypro/views/Gemini_AI/chat_screen.dart';
import 'package:studypro/views/Gemini_AI/pdf_chat_screen/pdf_qa_screen.dart';
import 'package:studypro/views/Gemini_AI/quiz.dart';
import 'package:studypro/views/Gemini_AI/grammar_check/grammar_check.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class GeminiScreen extends StatefulWidget {
  const GeminiScreen({super.key});

  @override
  State<GeminiScreen> createState() => _GeminiScreenState();
}

class _GeminiScreenState extends State<GeminiScreen> {
  final List<Map<String, dynamic>> _features = [
    {
      'title': 'Chat with Gemini',
      'icon': Icons.chat_bubble_outline,
      'screen': const ChatWithGeminiScreen(),
      'gradient': const LinearGradient(
        colors: [AppColors.primary, AppColors.primaryDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'title': 'Take a Quiz',
      'icon': Icons.quiz_outlined,
      'screen': const GeminiQuizScreen(),
      'gradient': const LinearGradient(
        colors: [AppColors.success, Color(0xFF16A34A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'title': 'Chat with PDF',
      'icon': Icons.picture_as_pdf_outlined,
      'screen': const PdfQAScreen(),
      'gradient': const LinearGradient(
        colors: [AppColors.info, Color(0xFF4B5563)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'title': 'Grammar Check',
      'icon': Icons.spellcheck_outlined,
      'screen': const GrammarCheckerScreen(),
      'gradient': const LinearGradient(
        colors: [AppColors.warning, Color(0xFFD97706)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
  ];

  final List<String> _carouselImages = [
    'https://lh3.googleusercontent.com/-N-Y3an_9Yd7bGCwqfe9kCRjlhEeBER1JGzHJIHEMLc7SJx_hlnnncMXrSx168TiHHrW2Kf2eG3SQa5YvTClBgPHYK8=s1280-w1280-h800',
    'https://img.freepik.com/free-vector/sunburst-background-questionnaire-with-pencil_23-2147593791.jpg',
    'https://cdn.mos.cms.futurecdn.net/sD9objsEAPDccSXYjH4ybE.jpg',
    'https://is1-ssl.mzstatic.com/image/thumb/Purple221/v4/8d/23/77/8d2377e9-22b7-fcaf-2f2d-ed09bf76e037/AppIcon-0-0-1x_U007epad-0-1-0-85-220.png/512x512bb.jpg',
  ];

  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required Widget screen,
    required LinearGradient gradient,
  }) {
    
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
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
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => screen),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                 SizedBox(height: SizeConfig().scaleHeight(12, context)),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return CarouselSlider.builder(
      itemCount: _carouselImages.length,
      options: CarouselOptions(
        height: SizeConfig().scaleHeight(160, context),
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 3),
        enlargeCenterPage: true,
        viewportFraction: 0.85,
        aspectRatio: 2.0,
      ),
      itemBuilder: (context, index, realIdx) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow(context),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: _carouselImages[index],
              fit: BoxFit.cover,
              imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: themeProvider.isDarkMode
                    ? const Color(0xFF2D2D2D)
                    : const Color(0xFFE0E0E0),
                highlightColor: themeProvider.isDarkMode
                    ? const Color(0xFF424242)
                    : const Color(0xFFF5F5F5),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.cardBackground(context),
                child: Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 40,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: AppColors.cardBackground(context),
        title: Text(
          'Gemini Features',
          style: TextStyle(
           fontWeight: FontWeight.w600, color: Colors.white,fontSize: 24
          ),
        ),
        flexibleSpace: Container(
          decoration:  BoxDecoration(
           gradient:  LinearGradient(
  colors: themeProvider.isDarkMode
      ? [Color.fromARGB(255, 32, 32, 32), Color.fromARGB(255, 48, 48, 48)]
      : [Colors.blue, const Color.fromARGB(255, 36, 36, 36)], 
  begin: Alignment.topRight,
  end: Alignment.bottomLeft,
),
          ),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 600;
          final padding = isTablet ? 24.0 : 16.0;
          final crossAxisCount = isTablet ? 3 : 2;
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  _buildCarousel(),
                  SizedBox(height: padding),
                  SizedBox(height: SizeConfig().scaleHeight(10, context),),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: padding,
                      mainAxisSpacing: padding,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: _features.length,
                    itemBuilder: (context, index) {
                      final feature = _features[index];
                      return _buildFeatureCard(
                        title: feature['title'],
                        icon: feature['icon'],
                        screen: feature['screen'],
                        gradient: feature['gradient'],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}