import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:provider/provider.dart';
import 'package:studypro/providers/theme_provider.dart';
import 'package:studypro/views/view_course_screen.dart';

class CategoryCoursesScreen extends StatefulWidget {
  final String category;

  const CategoryCoursesScreen({
    super.key,
    required this.category,
  });

  @override
  State<CategoryCoursesScreen> createState() => _CategoryCoursesScreenState();
}

class _CategoryCoursesScreenState extends State<CategoryCoursesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> courseStream;

  @override
  void initState() {
    super.initState();
    courseStream = _firestore
        .collection('courses')
        .where('category', isEqualTo: widget.category)
        .snapshots();
  }

  Future<Map<String, Map<String, dynamic>>> getMultipleCourseRatingStats(List<String> courseIds) async {
    final Map<String, Map<String, dynamic>> stats = {};

    if (courseIds.isEmpty) {
      return stats;
    }

    const batchSize = 10;
    for (var i = 0; i < courseIds.length; i += batchSize) {
      final batchIds = courseIds.sublist(
        i,
        i + batchSize > courseIds.length ? courseIds.length : i + batchSize,
      );

      final querySnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('courseId', whereIn: batchIds)
          .get();

      for (String courseId in batchIds) {
        stats[courseId] = {
          'totalReviews': 0,
          'averageRating': 0.0,
          'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      for (var doc in querySnapshot.docs) {
        final courseId = doc['courseId'] as String;
        final rating = doc['rating'] as int;
        final statsForCourse = stats[courseId]!;

        statsForCourse['totalReviews'] = (statsForCourse['totalReviews'] as int) + 1;
        statsForCourse['averageRating'] = (statsForCourse['averageRating'] as double) + rating;
        statsForCourse['ratingDistribution'][rating] = (statsForCourse['ratingDistribution'][rating] as int) + 1;
      }
    }

    for (String courseId in courseIds) {
      final totalReviews = stats[courseId]!['totalReviews'] as int;
      final totalRating = stats[courseId]!['averageRating'] as double;
      stats[courseId]!['averageRating'] = totalReviews > 0 ? totalRating / totalReviews : 0.0;
    }

    return stats;
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          '${widget.category} Courses',
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Explore ${widget.category} Courses',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StreamBuilder<QuerySnapshot>(
                  stream: courseStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Error loading courses',
                          style: TextStyle(fontSize: 16, color: Colors.red),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.book_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No courses available in ${widget.category}',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Check back later for new courses!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final courseIds = snapshot.data!.docs
                        .map((doc) => doc['courseId'] as String)
                        .toList();

                    return FutureBuilder<Map<String, Map<String, dynamic>>>(
                      future: getMultipleCourseRatingStats(courseIds),
                      builder: (context, reviewSnapshot) {
                        if (reviewSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (reviewSnapshot.hasError) {
                          return const Center(child: Text('Error loading reviews'));
                        }

                        final reviewStats = reviewSnapshot.data ?? {};

                        return ListView.builder(
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final course = snapshot.data!.docs[index];
                            final courseData = course.data() as Map<String, dynamic>;
                            final courseId = course['courseId'];

                            final stats = reviewStats[courseId] ?? {
                              'totalReviews': 0,
                              'averageRating': 0.0,
                              'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
                            };

                            final titleController = QuillController(
                              document: Document.fromJson(courseData['titleRich']),
                              selection: const TextSelection.collapsed(offset: 0),
                              config: const QuillControllerConfig(),
                            );

                            final String videoDescription = (courseData['playlist'] != null &&
                                    courseData['playlist'] is List &&
                                    courseData['playlist'].isNotEmpty &&
                                    courseData['playlist'][0]['description'] != null)
                                ? courseData['playlist'][0]['description']
                                : 'No description available';

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ViewCourseScreen(
                                        courseId: courseId,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(15),
                                child: Card(
                                  shadowColor: themeProvider.isDarkMode
                                      ? const Color.fromARGB(133, 192, 191, 191)
                                      : Colors.grey[300],
                                  elevation: 8,
                                  color: themeProvider.isDarkMode
                                      ? const Color.fromARGB(255, 32, 32, 32)
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (courseData['thumbnailUrl'] != null)
                                        ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl: courseData['thumbnailUrl'],
                                            height: height * 0.22,
                                            width: width,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(
                                              height: height * 0.22,
                                              color: Colors.grey[200],
                                              child: const Center(
                                                child: CircularProgressIndicator(),
                                              ),
                                            ),
                                            errorWidget: (context, url, error) => Container(
                                              height: height * 0.22,
                                              color: Colors.grey[200],
                                              child: const Center(
                                                child: Icon(
                                                  Icons.error_outline,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 16, right: 16, bottom: 16, top: 3),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: QuillEditor(
                                                controller: titleController,
                                                focusNode: FocusNode(canRequestFocus: false),
                                                scrollController: ScrollController(),
                                                config: QuillEditorConfig(
                                                  embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              videoDescription,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: themeProvider.isDarkMode
                                                    ? Colors.white70
                                                    : Colors.black87,
                                                height: 1.4,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.star,
                                                        size: 14,
                                                        color: Colors.amber,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${stats['averageRating'].toStringAsFixed(1)} / 5 (${stats['totalReviews']})',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const Spacer(),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        Icons.access_time,
                                                        size: 12,
                                                        color: Colors.blue[700],
                                                      ),
                                                      const SizedBox(width: 5),
                                                      Text(
                                                        courseData['duration'] ?? 'N/A',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w500,
                                                          color: Colors.blue[700],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 3),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (courseData['createdByUsername'] != null) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                'By ${courseData['createdByUsername']}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: themeProvider.isDarkMode
                                                      ? Colors.white70
                                                      : Colors.black54,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}