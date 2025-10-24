import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:provider/provider.dart';
import 'package:studypro/providers/auth_providers/login_provider.dart';
import 'package:studypro/providers/theme_provider.dart';
import 'package:studypro/views/view_course_screen.dart';

class CurrentTeacherCourse extends StatefulWidget {
  const CurrentTeacherCourse({super.key});

  @override
  State<CurrentTeacherCourse> createState() => _CurrentTeacherCourseState();
}

class _CurrentTeacherCourseState extends State<CurrentTeacherCourse> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> courseStream;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final String? email = loginProvider.email;
    print('Initializing courseStream with email: $email');
    if (email == null) {
      print('Warning: email is null, returning empty stream');
      courseStream = Stream.empty();
    } else {
      courseStream = firestore
          .collection('courses')
          .where('createdBy', isEqualTo: email)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginProvider = Provider.of<LoginProvider>(context);
    final String? userRole = loginProvider.userRole;
    final String? email = loginProvider.email;
    print('UserRole: "$userRole"');
    print('Email: "$email"');

    final themeProvider = Provider.of<ThemeProvider>(context);
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;

    Future<Map<String, Map<String, dynamic>>> getMultipleCourseRatingStats(List<String> courseIds) async {
    final Map<String, Map<String, dynamic>> stats = {};

    if (courseIds.isEmpty) {
      print('No course IDs provided for review stats');
      return stats;
    }

    print('Fetching review stats for course IDs: $courseIds');

    const batchSize = 10;
    for (var i = 0; i < courseIds.length; i += batchSize) {
      final batchIds = courseIds.sublist(
        i,
        i + batchSize > courseIds.length ? courseIds.length : i + batchSize,
      );
      print('Processing batch: $batchIds');

      final querySnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('courseId', whereIn: batchIds)
          .get();

      print('Found ${querySnapshot.docs.length} reviews for batch');

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
        print('Review for courseId: $courseId, rating: $rating');
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
      print('Stats for $courseId: totalReviews=$totalReviews, averageRating=${stats[courseId]!['averageRating']}');
    }

    return stats;
  }
final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: width * 0.02),
            child: Column(
              children: [
                SizedBox(
                    height: height * 0.06,
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) {
                        setState(() {}); 
                      },
                      decoration: InputDecoration(
                        hintText: 'Search your topic',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: height * 0.01),
                StreamBuilder<QuerySnapshot>(
                  stream: courseStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      print('StreamBuilder error: ${snapshot.error}');
                      return const Center(child: Text('Error loading courses'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      print('No courses found for email: $email');
                      return const Center(child: Text('No courses available'));
                    }
                    print('Courses found: ${snapshot.data!.docs.length}');
                    snapshot.data!.docs.forEach((doc) {
                      print('Course ID: ${doc.id}, Data: ${doc.data()}');
                    });
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
                                final filteredCourses = snapshot.data!.docs.where((doc) {
                                  final courseData = doc.data() as Map<String, dynamic>;
                                  final titleController = QuillController(
                                    document: Document.fromJson(courseData['titleRich']),
                                    selection: const TextSelection.collapsed(offset: 0),
                                    config: const QuillControllerConfig(),
                                  );
                                  final titleText = titleController.document.toPlainText().toLowerCase();
                                  final searchText = searchController.text.toLowerCase();
                                  return searchText.isEmpty || titleText.contains(searchText);
                                }).toList();
                          
                                if (filteredCourses.isEmpty) {
                                  return const Center(child: Text('No courses match your search'));
                                }
                          
                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filteredCourses.length,
                                  itemBuilder: (context, index) {
                                    final course = filteredCourses[index];
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
                                      margin: const EdgeInsets.symmetric(vertical: 5),
                                      child: InkWell(
                                        onTap: () {
                                          FocusScope.of(context).unfocus(); 
                                          searchController.clear(); 
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
                                          elevation: 8,
                                          shadowColor: themeProvider.isDarkMode
                                              ? const Color.fromARGB(133, 192, 191, 191)
                                              : Colors.grey[300],
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
                                                    height: height * 0.2,
                                                    width: width,
                                                    fit: BoxFit.cover,
                                                    placeholder: (context, url) => const Center(
                                                      child: CircularProgressIndicator(),
                                                    ),
                                                    errorWidget: (context, url, error) => const Icon(
                                                      Icons.error,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              Padding(
                                                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 3),
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
                                                        fontSize: 13,
                                                        color: themeProvider.isDarkMode
                                                            ? Colors.white70
                                                            : Colors.black87,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                                              Icon(Icons.access_time, size: 12, color: Colors.blue[700]),
                                                              const SizedBox(width: 5),
                                                              Text(
                                                                courseData['duration'] ?? 'N/A',
                                                                style: const TextStyle(fontSize: 12),
                                                              ),
                                                              const SizedBox(width: 3),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}