import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studypro/overview.dart';
import 'package:studypro/providers/theme_provider.dart';
import 'package:studypro/views/category_screen.dart';
import 'package:studypro/views/detail_progress.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var shading = Colors.grey.shade400;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String uid = FirebaseAuth.instance.currentUser!.uid;

  StreamSubscription? chatSubscription;
  String? username;
  bool isUsernameLoaded = false;
  
  List<String> courseCategories = [];
  bool isCategoriesLoaded = false;

  @override
  void initState() {
    super.initState();
    _fetchUsername();
    _fetchCategories();
  }

  Future<void> _fetchUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        username = 'anonymous_user';
        isUsernameLoaded = true;
      });
      return;
    }

    try {
      final snapshot = await _firestore.collection('users').doc(user.uid).get();
      if (snapshot.exists) {
        setState(() {
          username = snapshot.data()?['username'] ?? 'user_${user.uid.substring(0, 8)}';
          isUsernameLoaded = true;
        });
      } else {
        setState(() {
          username = 'user_${user.uid.substring(0, 8)}';
          isUsernameLoaded = true;
        });
      }
    } catch (e) {
      debugPrint("Error fetching username: $e");
      setState(() {
        username = 'user_${user.uid.substring(0, 8)}';
        isUsernameLoaded = true;
      });
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final snapshot = await _firestore.collection('courses').get();
      Set<String> uniqueCategories = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['category'] != null) {
          uniqueCategories.add(data['category'].toString());
        }
      }
      
      setState(() {
        courseCategories = uniqueCategories.toList();
        courseCategories.sort(); 
        isCategoriesLoaded = true;
      });
    } catch (e) {
      debugPrint("Error fetching categories: $e");
      
      setState(() {
        courseCategories = ['Programming', 'Design', 'Business', 'Data Science', 'Marketing', 'Other'];
        isCategoriesLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    chatSubscription?.cancel();
    super.dispose();
  }
  String getCategoryImage(String category) {
    final Map<String, String> categoryImages = {
      'Programming': 'https://media.licdn.com/dms/image/v2/C4D12AQGG1t8m6P_cCQ/article-cover_image-shrink_720_1280/article-cover_image-shrink_720_1280/0/1542125872273?e=1760572800&v=beta&t=7NZrkpoCkSOzJsc-2F0HvNk3k5cgmsVAlsBupaiKQq0',
      'Design': 'https://img.freepik.com/free-photo/ideas-design-draft-creative-sketch-objective-concept_53876-121105.jpg',
      'Business': 'https://freedesignfile.com/upload/2014/05/Creative-business-Idea-template-graphics-vector-01.jpg',
      'Data Science': 'https://www.fsm.ac.in/blog/wp-content/uploads/2022/07/FUqHEVVUsAAbZB0.jpg',
      'Marketing': 'https://www.simplilearn.com/ice9/free_resources_article_thumb/What_is_digital_marketing.jpg',
      'Other': 'https://img.freepik.com/free-vector/people-analyzing-growth-charts-illustrated_23-2148865275.jpg',
    };
    
    return categoryImages[category] ?? 'https://img.freepik.com/free-vector/people-analyzing-growth-charts-illustrated_23-2148865275.jpg';
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> logout(BuildContext context) async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Error during logout: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    var height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'StudyPro',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white,fontSize: 27),
        ),
        flexibleSpace: Container(
          decoration:  BoxDecoration(
           gradient:  LinearGradient(
  colors: themeProvider.isDarkMode
      ? [Color.fromARGB(255, 32, 32, 32), Color.fromARGB(255, 48, 48, 48)]
      : [Colors.blue, Colors.black],
  begin: Alignment.topRight,
  end: Alignment.bottomLeft,
),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.12,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                 gradient:  LinearGradient(
  colors: themeProvider.isDarkMode
      ? [Color.fromARGB(255, 32, 32, 32), Color.fromARGB(255, 48, 48, 48)] 
      : [Colors.blue, Colors.black], 
  begin: Alignment.topRight,
  end: Alignment.bottomLeft,
),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(27),
                    bottomRight: Radius.circular(27),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: themeProvider.isDarkMode ? const Color.fromARGB(135, 102, 101, 101) : (Colors.grey[300] ?? Colors.grey),
                     spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     SizedBox(height: height*(10/812)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isUsernameLoaded ? "Hi, $username" : "Hi...",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Text(
                        "Let's start learning!",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                 
                    
                  ],
                ),
              ),
               SizedBox(height: height*(20/812)),
              Container(
                margin: const EdgeInsets.only(left: 23),
                child: Row(
                  children: [
                    DefaultTextStyle(
                      style:  TextStyle(
                        fontSize: 27,
                        color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      child: AnimatedTextKit(
                        totalRepeatCount: 2,
                        animatedTexts: [
                          TypewriterAnimatedText(
                            'Explore categories',
                            speed: const Duration(milliseconds: 50),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
               SizedBox(height: height*(10/812)),
              isCategoriesLoaded 
                ? SizedBox(
                    height: height*(150/812),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: courseCategories.length,
                      itemBuilder: (context, index) {
                        final category = courseCategories[index];
                        final imageUrl = getCategoryImage(category);
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CategoryCoursesScreen(
                                  category: category,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 250,
                            margin: const EdgeInsets.only(right: 15),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              image: DecorationImage(
                                image: CachedNetworkImageProvider(imageUrl),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withOpacity(0.3),
                                  BlendMode.darken,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: themeProvider.isDarkMode ? const Color.fromARGB(133, 145, 144, 144) : (Colors.grey[300] ?? Colors.grey.shade300),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  bottom: 10,
                                  left: 10,
                                  child: Text(
                                    category,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                :  SizedBox(
                    height: height*(150/812),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
               SizedBox(height: height*(20/812)),
                InkWell(
                  onTap: (){
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => const ProgressDetailScreen()));
                  },
                  child: Container(
                  margin: const EdgeInsets.only(left: 23),
                  child: Row(
                    children: [
                      DefaultTextStyle(
                        style:  TextStyle(
                          fontSize: 27,
                          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        child: AnimatedTextKit(
                          totalRepeatCount: 1,
                          animatedTexts: [
                            TypewriterAnimatedText(
                              'In Progress',
                              speed: const Duration(milliseconds: 30),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                                ),
                ),

                 SizedBox(height: height*(20/812)),
InkWell(
  onTap: (){
      Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProgressDetailScreen(),
                ),
              );
  },
  child: const ProgressOverviewWidget()),
 SizedBox(height: height*(20/812)),
            ],
          ),
        ),
      ),
    );
  }
}