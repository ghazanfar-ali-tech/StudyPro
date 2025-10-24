import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:studypro/components/appColor.dart';
import 'package:studypro/providers/fav_provider.dart';
import 'package:studypro/providers/theme_provider.dart';
import 'package:studypro/views/view_course_screen.dart';

class FavoriteCoursesScreen extends StatelessWidget {
  const FavoriteCoursesScreen({super.key});



  @override
  Widget build(BuildContext context) {
    final favoriteCourses =
        Provider.of<FavoriteProvider>(context).favoriteCourses;

    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: AppColors.cardBackground(context),
        title: const Text(
          'Favourite Courses',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 24,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: themeProvider.isDarkMode
                  ? [
                      Color.fromARGB(255, 32, 32, 32),
                      Color.fromARGB(255, 48, 48, 48)
                    ]
                  : [Colors.blue, Color.fromARGB(255, 36, 36, 36)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: favoriteCourses.isEmpty
          ? const Center(
              child: Text(
                'No favorite courses yet.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: favoriteCourses.length,
              itemBuilder: (context, index) {
                final course = favoriteCourses[index];

                return Card(
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewCourseScreen(
                            courseId: course['courseId'],
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        // Thumbnail
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: course['thumbnailUrl'] ?? '',
                            height: 90,
                            width: 120,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error, color: Colors.red),
                          ),
                        ),

                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title
                                Text(
                                  course['title'] ?? 'Untitled Course',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            
                                const SizedBox(height: 8),

                                // Duration Row
                                Row(
                                  children: [
                                    Icon(Icons.access_time,
                                        size: 14,
                                        color: Colors.blue.shade600),
                                    const SizedBox(width: 3),
                                    Text(
                                      course['duration'] ?? 'N/A',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Icon(
                            Icons.star,
                            color: Color.fromARGB(225, 243, 139, 2),
                            size: 22,
                          ),
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
