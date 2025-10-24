import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:provider/provider.dart';
import 'package:studypro/components/appColor.dart';
import 'package:studypro/components/size_config.dart';
import 'package:studypro/models/courseModel.dart';
import 'package:studypro/providers/theme_provider.dart';
import 'package:studypro/providers/review_provider.dart';
import 'package:studypro/views/play_video_screen.dart';
import 'package:studypro/providers/course_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studypro/views/widgets/review_dialog.dart';

class ViewCourseScreen extends StatefulWidget {
  final String? courseId;
  final String? docId;

  const ViewCourseScreen({super.key, this.courseId, this.docId});

  @override
  State<ViewCourseScreen> createState() => _ViewCourseScreenState();
}

class _ViewCourseScreenState extends State<ViewCourseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCourseData();
    });
  }

  void _loadCourseData() {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);

    String courseId;
    if (widget.courseId != null) {
      courseId = widget.courseId!;
      courseProvider.fetchCourseById(courseId);
    } else if (widget.docId != null) {
      courseId = widget.docId!;
      courseProvider.fetchCourseByDocId(courseId);
    } else {
      return;
    }

    reviewProvider.loadCourseReviews(courseId);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      reviewProvider.loadUserReview(courseId, user.uid);
    }
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
      body: Consumer<CourseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error.isNotEmpty) {
            return _buildErrorWidget(provider);
          }

          final course = provider.selectedCourse;
          if (course == null) {
            return const Center(child: Text('No course data available'));
          }

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(course),
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 20,
                  ),
                  child: Column(
                    children: [
                      _buildCourseInfo(course, provider),
                      _buildTabSection(course, provider),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(CourseProvider provider) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Course Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
             SizedBox(height: SizeConfig().scaleHeight(16, context)),
            Text(
              'Error: ${provider.error}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
             SizedBox(height: SizeConfig().scaleHeight(16, context)),
            ElevatedButton(
              onPressed: _loadCourseData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(Course course) {
    return SliverAppBar(
      expandedHeight: 250,
      floating: false,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            course.thumbnailUrl.isNotEmpty
                ? Image.network(
                    course.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    decoration:
                        const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ).createShader(
                              const Rect.fromLTRB(0, 0, 200, 70),
                            ) !=
                            null
                        ? BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                          )
                        : const BoxDecoration(color: Colors.grey),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
          ],
        ),
      ),
     
    );
  }

  Widget _buildCourseInfo(Course course, CourseProvider provider) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, child) {
        return Container(
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode
                ? const Color.fromARGB(255, 32, 32, 32)
                : Colors.white,
          ),
          width: double.infinity,
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 5,
            bottom: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
               SizedBox(height: SizeConfig().scaleHeight(12, context)),

              Container(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: 12,
                ),
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode
                      ? const Color.fromARGB(255, 32, 32, 32)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: themeProvider.isDarkMode
                          ? const Color.fromARGB(135, 102, 101, 101)
                          : (Colors.grey[300] ?? Colors.grey),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      Icons.play_circle_outline,
                      provider.getFormattedVideoCount(),
                      'Videos',
                      Colors.blue,
                    ),
                    _buildStatDivider(),
                    _buildStatItem(
                      Icons.access_time,
                      provider.getFormattedDuration(),
                      'Duration',
                      Colors.green,
                    ),
                    _buildStatDivider(),
                    _buildStatItem(
                      Icons.star,
                      reviewProvider.getFormattedAverageRating(),
                      '${reviewProvider.getTotalReviews()}',
                      Color.fromARGB(225, 243, 139, 2),
                    ),
                  ],
                ),
              ),
               SizedBox(height: SizeConfig().scaleHeight(12, context)),
             
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
         SizedBox(height: SizeConfig().scaleHeight(4, context)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(height: SizeConfig().scaleHeight(40, context), width: 1, color: Colors.grey[300]);
  }

  Widget _buildTabSection(Course course, CourseProvider provider) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode
            ? const Color.fromARGB(255, 32, 32, 32)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode
                ? const Color.fromARGB(135, 102, 101, 101)
                : (Colors.grey[300] ?? Colors.grey),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            indicatorWeight: 3,
            tabs: const [
              Tab(icon: Icon(Icons.description), text: "Overview"),
              Tab(icon: Icon(Icons.video_library), text: "Lessons"),
              Tab(icon: Icon(Icons.reviews), text: "Reviews"),
            ],
          ),
          SizedBox(
            height: SizeConfig().scaleHeight(400, context),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(course),
                _buildLessonsTab(course),
                _buildReviewsTab(course),
              ],
            ),
          ),
          _buildActionButtons(course),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Course course) {
    final user = FirebaseAuth.instance.currentUser;

    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (user != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showReviewDialog(course, reviewProvider),
                    icon: Icon(
                      reviewProvider.hasUserReviewed()
                          ? Icons.edit
                          : Icons.rate_review,
                      color: Colors.white,
                    ),
                    label: Text(
                      reviewProvider.hasUserReviewed()
                          ? "Edit Review"
                          : "Add Review",
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: reviewProvider.hasUserReviewed()
                          ? Colors.orange
                          : Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showReviewDialog(Course course, ReviewProvider reviewProvider) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to add a review'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String getUserName() {
      if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
        return user.displayName!.trim();
      }

      if (user.email != null && user.email!.isNotEmpty) {
        final emailPrefix = user.email!.split('@').first;
        if (emailPrefix.isNotEmpty) {
          return emailPrefix;
        }
      }

      return 'Anonymous User';
    }

    final userName = getUserName();
    print(' userName: "$userName"');
    print(' displayName: "${user.displayName}"');
    print(' email: "${user.email}"');

    showDialog(
      context: context,
      builder: (context) => AddReviewDialog(
        courseId: widget.courseId ?? widget.docId ?? '',
        userId: user.uid,
        userName: userName,
        userEmail: user.email ?? '',
        existingReview: reviewProvider.userReview,
      ),
    );
  }

Widget _buildOverviewTab(Course course) {
  final themeProvider = Provider.of<ThemeProvider>(context);

  print('Course descriptionRich: ${course.descriptionRich}');
  print('Course description: ${course.description}');

  final descriptionController = QuillController(
    document: () {
      if (course.descriptionRich != null && course.descriptionRich!.isNotEmpty) {
        try {
          return Document.fromJson(course.descriptionRich!);
        } catch (e) {
          print('Error parsing descriptionRich: $e');
          return Document()..insert(0, 'Invalid rich text description');
        }
      } else {
        return Document()
          ..insert(
            0,
            course.description.isNotEmpty
                ? course.description
                : 'No description available',
          );
      }
    }(),
    selection: const TextSelection.collapsed(offset: 0),
    config: const QuillControllerConfig(),
  );

  print('QuillController plain text: ${descriptionController.document.toPlainText()}');

  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About this course',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: themeProvider.isDarkMode
                ? Colors.white
                : const Color.fromARGB(255, 32, 32, 32),
          ),
        ),
         SizedBox(height: SizeConfig().scaleHeight(12, context)),
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: QuillEditor(
            controller: descriptionController,
            focusNode: FocusNode(canRequestFocus: false),
            scrollController: ScrollController(),
            config: QuillEditorConfig(
              embedBuilders: FlutterQuillEmbeds.editorBuilders(),
              autoFocus: false,
             
              placeholder: 'No description available',
            ),
          ),
        ),
         SizedBox(height: SizeConfig().scaleHeight(20, context)),
        if (course.totalPdfs > 0 || course.totalUrls > 0) ...[
          Text(
            'What you\'ll get',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeProvider.isDarkMode
                  ? Colors.white
                  : const Color.fromARGB(255, 32, 32, 32),
            ),
          ),
           SizedBox(height: SizeConfig().scaleHeight(12, context)),
          if (course.totalPdfs > 0)
            _buildFeatureItem(
              Icons.picture_as_pdf,
              '${course.totalPdfs} PDF resources',
              Colors.red,
            ),
          if (course.totalUrls > 0)
            _buildFeatureItem(
              Icons.link,
              '${course.totalUrls} reference links',
              Colors.blue,
            ),
          _buildFeatureItem(
            Icons.badge_outlined,
            'Certificate of completion',
            Colors.green,
          ),
          _buildFeatureItem(
            Icons.access_time,
            'Lifetime access',
            Colors.orange,
          ),
        ],
      ],
    ),
  );
}
  Widget _buildFeatureItem(IconData icon, String text, Color color) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
           SizedBox(width: SizeConfig().scaleWidth(12, context)),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: themeProvider.isDarkMode
                  ? AppColors.primaryLight
                  : const Color.fromARGB(255, 32, 32, 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsTab(Course course) {
    if (course.playlist.isEmpty) {
      return  Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
            SizedBox(height: SizeConfig().scaleHeight(16, context)),
            Text(
              'No lessons available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }
  final themeProvider = Provider.of<ThemeProvider>(context);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: course.playlist.length,
      itemBuilder: (context, index) {
        final video = course.playlist[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
       

decoration: BoxDecoration(
  color: themeProvider.isDarkMode
      ? const Color(0xFF1E1E1E) 
      : const Color(0xFFF9F9F9), 
  borderRadius: BorderRadius.circular(12),
  border: Border.all(
    color: AppColors.border(context)
  ),
  boxShadow: [
    BoxShadow(
      color: themeProvider.isDarkMode
          ? Colors.black.withOpacity(0.4)
          : Colors.grey.withOpacity(0.2),
      blurRadius: 6,
      offset: const Offset(0, 3),
    ),
  ],
),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
  width: SizeConfig().scaleWidth(50, context),
  height: SizeConfig().scaleHeight(50, context),
  decoration: BoxDecoration(
    color: themeProvider.isDarkMode
        ? const Color(0xFF2C2C2C) 
        : const Color(0xFFE3F2FD),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Icon(
    Icons.play_arrow,
    color: themeProvider.isDarkMode
        ? const Color(0xFF90CAF9) 
        : Colors.blue,            
    size: 24,
  ),
),

            title: Text(
              video.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (video.description.isNotEmpty) ...[
                   SizedBox(height: SizeConfig().scaleHeight(4, context)),
                  Text(
                    video.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
                 SizedBox(height: SizeConfig().scaleHeight(8, context)),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                     SizedBox(width: SizeConfig().scaleWidth(4, context)),
                    Text(
                      video.videoDuration.isNotEmpty
                          ? video.videoDuration
                          : '00:00',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (video.pdfUrls.isNotEmpty) ...[
                       SizedBox(width: SizeConfig().scaleWidth(12, context)),
                      const Icon(
                        Icons.picture_as_pdf,
                        size: 14,
                        color: Colors.red,
                      ),
                       SizedBox(width: SizeConfig().scaleWidth(4, context)),
                      const Text(
                        'PDF',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PlayVideoScreen(courseId: widget.courseId, video: video),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildReviewsTab(Course course) {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, child) {
        if (reviewProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (reviewProvider.error.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                 SizedBox(height: SizeConfig().scaleHeight(16, context)),
                Text(
                  'Error loading reviews: ${reviewProvider.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                 SizedBox(height: SizeConfig().scaleHeight(16, context)),
                ElevatedButton(
                  onPressed: () {
                    final courseId = widget.courseId ?? widget.docId ?? '';
                    reviewProvider.loadCourseReviews(courseId);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final reviews = reviewProvider.reviews;

        if (reviews.isEmpty) {
          return  Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.reviews_outlined, size: 64, color: Colors.grey),
                SizedBox(height: SizeConfig().scaleHeight(16, context)),
                Text(
                  'No reviews yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: SizeConfig().scaleHeight(8, context)),
                Text(
                  'Be the first to review this course!',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reviewProvider.getFormattedAverageRating(),
                        style:  TextStyle(
                          color: AppColors.textPrimary(context),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            Icons.star,
                            size: 20,
                            color:
                                index <
                                    int.parse(
                                      reviewProvider
                                          .getFormattedAverageRating()
                                          .split('.')[0],
                                    )
                                ? Colors.amber
                                : Colors.grey[300],
                          ),
                        ),
                      ),

                      Text(
                        '${reviewProvider.getTotalReviews()} reviews',
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary(context)),
                      ),
                    ],
                  ),
                   SizedBox(width: SizeConfig().scaleWidth(20, context)),
                  Expanded(
                    child: Column(
                      children: List.generate(5, (index) {
                        final rating = 5 - index;
                        final distribution = reviewProvider
                            .getRatingDistribution();
                        final count = distribution[rating] ?? 0;
                        final total = reviewProvider.getTotalReviews();
                        final percentage = total > 0 ? (count / total) : 0.0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Text('$rating'),
                               SizedBox(width: SizeConfig().scaleWidth(8, context)),
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: percentage,
                                  backgroundColor: Colors.grey[300],
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Colors.amber,
                                      ),
                                ),
                              ),
                               SizedBox(width: SizeConfig().scaleWidth(8, context)),
                              Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary(context)
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground(context),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow(context)
                        )
                      ],
                      border: Border.all(
                      color: AppColors.border(context), 
                       ),

                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.blue[100],
                              child: Text(
                                review.userName.isNotEmpty
                                    ? review.userName
                                          .substring(0, 1)
                                          .toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                             SizedBox(width: SizeConfig().scaleWidth(12, context)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    review.userName.isNotEmpty
                                        ? review.userName
                                        : 'Anonymous User',
                                    style:  TextStyle(
                                      color: AppColors.textPrimary(context),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      ...List.generate(
                                        5,
                                        (i) => Icon(
                                          Icons.star,
                                          size: 16,
                                          color: i < review.rating
                                              ? Colors.amber
                                              : Colors.grey[300],
                                        ),
                                      ),
                                       SizedBox(width: SizeConfig().scaleWidth(8, context)),
                                      Text(
                                        review.getFormattedDate(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary(context)
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (review.comment.isNotEmpty) ...[
                           SizedBox(height: SizeConfig().scaleHeight(12, context)),
                          Text(
                            review.comment,
                            style:  TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary(context),
                              fontWeight: FontWeight.w700
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
