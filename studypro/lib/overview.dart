import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studypro/components/appColor.dart';
import 'package:studypro/providers/theme_provider.dart';
import 'package:studypro/services/progressive_services.dart';
import 'package:studypro/views/detail_progress.dart';

class ProgressOverviewWidget extends StatefulWidget {
  const ProgressOverviewWidget({super.key});

  @override
  State<ProgressOverviewWidget> createState() => _ProgressOverviewWidgetState();
}

class _ProgressOverviewWidgetState extends State<ProgressOverviewWidget> {
  late Future<Map<String, dynamic>> _progressFuture;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  void _loadProgress() {
    _progressFuture = ProgressService.getProgressSummary();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final height = MediaQuery.of(context).size.height;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode 
            ? const Color.fromARGB(255, 48, 48, 48)
            : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode 
                ? const Color.fromARGB(133, 145, 144, 144)
                : Colors.grey.shade300,
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          if (!authSnapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 48,
                      color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                     SizedBox(height: height*(12/812)),
                    Text(
                      'Please log in to view progress',
                      style: TextStyle(
                        fontSize: 16,
                        color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return FutureBuilder<Map<String, dynamic>>(
            future: _progressFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                debugPrint('Progress Error: ${snapshot.error}');
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                         SizedBox(height: height*(12/812)),
                        Text(
                          'Error loading progress',
                          style: TextStyle(
                            fontSize: 16,
                            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                         SizedBox(height: height*(8/812)),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _loadProgress();
                            });
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final data = snapshot.data ?? {};
              final totalVideos = data['totalVideos'] ?? 0;
              final totalHours = data['totalHours'] ?? 0.0;
              final coursesInProgress = data['coursesInProgress'] ?? 0;
              final averageProgress = data['averageProgress'] ?? 0.0;

              return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Your Progress',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProgressDetailScreen(),
                ),
              );
            },
            icon: Icon(
              Icons.arrow_forward_ios,
              color: AppColors.iconSecondary(context),
              size: 20,
            ),
            style: IconButton.styleFrom(
              backgroundColor: themeProvider.isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[200],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(10),
            ),
          ),
        ],
      ),
       SizedBox(height: height* (8/812)),
      Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              'Videos Watched',
              totalVideos.toString(),
              Icons.play_circle_filled,
              AppColors.primary,
              themeProvider.isDarkMode,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              context,
              'Hours Learned',
              totalHours.toStringAsFixed(1),
              Icons.schedule,
              AppColors.success,
              themeProvider.isDarkMode,
            ),
          ),
        ],
      ),
       SizedBox(height: height*(8/812)),
      Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              'Courses',
              coursesInProgress.toString(),
              Icons.book,
              AppColors.warning,
              themeProvider.isDarkMode,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              context,
              'Avg Progress',
              '${averageProgress.toStringAsFixed(0)}%',
              Icons.trending_up,
              AppColors.info,
              themeProvider.isDarkMode,
            ),
          ),
        ],
      ),
    ],
  );
            },
          );
        },
      ),
    );
  }

 Widget _buildStatCard(
  BuildContext context,
  String title,
  String value,
  IconData icon,
  Color accentColor,
  bool isDark,
) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: isDark
            ? [AppColors.cardBackground(context), AppColors.cardBackground(context).withOpacity(0.7)]
            : [Colors.white, accentColor.withOpacity(0.1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: AppColors.border(context),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadow(context),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                accentColor.withOpacity(0.2),
                accentColor.withOpacity(0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Icon(
            icon,
            color: accentColor,
            size: 25,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(context),
          ),
        ),
       
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary(context),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
}