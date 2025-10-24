import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studypro/components/size_config.dart';
import 'package:studypro/models/progress_model.dart';
import 'package:studypro/providers/theme_provider.dart';
import 'package:studypro/services/progressive_services.dart';

class ProgressDetailScreen extends StatefulWidget {
  const ProgressDetailScreen({super.key});

  @override
  State<ProgressDetailScreen> createState() => _ProgressDetailScreenState();
}

class _ProgressDetailScreenState extends State<ProgressDetailScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: themeProvider.isDarkMode 
          ? const Color.fromARGB(255, 32, 32, 32) 
          : Colors.white,
      appBar: AppBar(
        title: const Text('Learning Progress'),
        backgroundColor: themeProvider.isDarkMode 
            ? const Color.fromARGB(255, 48, 48, 48)
            : Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Videos'),
            Tab(text: 'Skills'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(themeProvider),
          _buildVideosTab(themeProvider),
          _buildSkillsTab(themeProvider),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(ThemeProvider themeProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          FutureBuilder<Map<String, dynamic>>(
            future: ProgressService.getProgressSummary(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data ?? {};
              return Column(
                children: [
                  _buildProgressChart(data, themeProvider,context),
                   SizedBox(height: SizeConfig().scaleHeight(30, context)),
                  _buildDetailedStats(data, themeProvider),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVideosTab(ThemeProvider themeProvider) {
    return StreamBuilder<List<VideoProgress>>(
      stream: ProgressService.getVideoProgressStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final progressList = snapshot.data ?? [];
        
        if (progressList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.video_library_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                 SizedBox(height: SizeConfig().scaleHeight(16, context),),
                Text(
                  'No videos watched yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: progressList.length,
          itemBuilder: (context, index) {
            final progress = progressList[index];
            return _buildVideoProgressCard(progress, themeProvider);
          },
        );
      },
    );
  }

  Widget _buildSkillsTab(ThemeProvider themeProvider) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ProgressService.getProgressSummary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ?? {};
        final skills = List<String>.from(data['skillsLearned'] ?? []);

        if (skills.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.psychology_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                 SizedBox(height: SizeConfig().scaleHeight(16, context),),
                Text(
                  'No skills learned yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: skills.length,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode
                    ? const Color.fromARGB(255, 48, 48, 48)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: Colors.green,
                    size: 24,
                  ),
                   SizedBox(width: SizeConfig().scaleWidth(12, context),),
                  Expanded(
                    child: Text(
                      skills[index],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProgressChart(Map<String, dynamic> data, ThemeProvider themeProvider, BuildContext context) {
  final totalVideos = data['totalVideos'] ?? 0;
  final averageProgress = data['averageProgress'] ?? 0.0;

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: themeProvider.isDarkMode
          ? const Color.fromARGB(255, 48, 48, 48)
          : const Color.fromARGB(255, 240, 238, 238),
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        Text(
          'Overall Progress',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
         SizedBox(height: MediaQuery.of(context).size.height * 0.01),
        SizedBox(
          width: SizeConfig().scaleWidth(150, context),
          height: SizeConfig().scaleHeight(150, context),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: averageProgress / 100,
                strokeWidth: 12,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${averageProgress.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                   SizedBox(height: MediaQuery.of(context).size.height *0.07 ),
                  Text(
                    'Complete',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: $totalVideos Videos',
                    style: TextStyle(
                      fontSize: 12,
                      color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}


  Widget _buildDetailedStats(Map<String, dynamic> data, ThemeProvider themeProvider) {
    final stats = [
      {'title': 'Videos Watched', 'value': data['totalVideos'].toString(), 'icon': Icons.play_circle_filled, 'color': Colors.blue},
      {'title': 'Hours Learned', 'value': (data['totalHours'] as double).toStringAsFixed(1), 'icon': Icons.schedule, 'color': Colors.green},
      {'title': 'Courses in Progress', 'value': data['coursesInProgress'].toString(), 'icon': Icons.book, 'color': Colors.orange},
      {'title': 'Skills Acquired', 'value': (data['skillsLearned'] as List).length.toString(), 'icon': Icons.psychology, 'color': Colors.purple},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode
                ? const Color.fromARGB(255, 48, 48, 48)
                : const Color.fromARGB(255, 240, 238, 238),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                stat['icon'] as IconData,
                size: 32,
                color: stat['color'] as Color,
              ),
               SizedBox(height: SizeConfig().scaleWidth(12, context),),
              Text(
                stat['value'] as String,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stat['title'] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoProgressCard(VideoProgress progress, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode
            ? const Color.fromARGB(255, 48, 48, 48)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progress.videoTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      progress.courseTitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${progress.progressPercentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
           SizedBox(height: SizeConfig().scaleHeight(12, context),),
          LinearProgressIndicator(
            value: progress.progressPercentage / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
           SizedBox(height: SizeConfig().scaleHeight(12, context),),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${_formatDuration(progress.watchedDuration)} / ${_formatDuration(progress.totalDuration)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${progress.watchedAt.day}/${progress.watchedAt.month}/${progress.watchedAt.year}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          if (progress.skillsLearned.isNotEmpty) ...[
             SizedBox(height: SizeConfig().scaleHeight(8, context),),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: progress.skillsLearned.map((skill) => Chip(
                label: Text(
                  skill,
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: Colors.blue.withOpacity(0.1),
                side: BorderSide(color: Colors.blue.withOpacity(0.3)),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }
}