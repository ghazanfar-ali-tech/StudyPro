import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:studypro/providers/auth_providers/login_provider.dart';
import 'package:studypro/providers/theme_provider.dart';
import 'package:studypro/routes/app_routes.dart';
import 'package:studypro/views/all_course_screen.dart';
import 'package:studypro/views/favourite_course/fav_course_screen.dart';
import 'package:studypro/views/home_screen.dart';
import 'package:studypro/views/gemini_screen.dart';
import 'package:studypro/views/settings.dart';

class MainPageScreen extends StatefulWidget {
  const MainPageScreen({super.key});

  @override
  State<MainPageScreen> createState() => _MainPageScreenState();
}

class _MainPageScreenState extends State<MainPageScreen> {
  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
  if (mounted) { 
    setState(() {
      _selectedIndex = index; 
    });
   
    try {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      print('Error during page animation: $e');
    }
  }
}

@override
Widget build(BuildContext context) {
  final loginProvider = Provider.of<LoginProvider>(context);
  final String? userRole = loginProvider.userRole;

  final screenWidth = MediaQuery.of(context).size.width;
  final isSmallScreen = screenWidth < 360;
  final bottomPadding = MediaQuery.of(context).padding.bottom;
  final theme = Theme.of(context);

  final themeProvider = Provider.of<ThemeProvider>(context);

  return Scaffold(
    body: PageView(
      controller: _pageController,
      onPageChanged: (index) {
        if (mounted) { 
          setState(() {
            _selectedIndex = index; 
          });
        }
      },
      children: const [
        HomeScreen(),
        AllCoursesScreen(),
        FavoriteCoursesScreen(),
        GeminiScreen(),
        SettingScreen(),
      ],
    ),
    bottomNavigationBar: Container(
      height: 56.0 + bottomPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: themeProvider.isDarkMode
              ? [Color.fromARGB(255, 32, 32, 32), Color.fromARGB(255, 48, 48, 48)]
              : [
                  Colors.blue[900]!,
                  const Color.fromARGB(255, 3, 64, 133),
                  const Color.fromARGB(255, 4, 38, 100),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode ? const Color.fromARGB(133, 5, 3, 3) : Colors.grey[300]!,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: GNav(
            gap: isSmallScreen ? 2 : 4,
            activeColor: Colors.white,
            iconSize: isSmallScreen ? 22 : 28,
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 10 : 14,
              vertical: 4,
            ),
            tabBackgroundColor: Colors.white.withOpacity(0.2),
            color: Colors.white70,
            textStyle: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w500,
            ),
            selectedIndex: _selectedIndex,
            onTabChange: (index) {
              _onItemTapped(index);
              print('Tab changed to index: $index');
            },
            rippleColor: Colors.white.withOpacity(0.5),
            backgroundColor: Colors.transparent,
            curve: Curves.easeInOut,
            duration: const Duration(milliseconds: 300),
            tabs: [
              GButton(
                icon: Icons.home,
                text: "Home",
                iconColor: _selectedIndex == 0 ? Colors.white : Colors.white70,
                textStyle: theme.textTheme.labelSmall?.copyWith(
                  color: _selectedIndex == 0 ? Colors.white : Colors.white70,
                ),
                semanticLabel: 'Home',
              ),
              GButton(
                icon: Icons.auto_stories_sharp,
                text: "My Courses",
                iconColor: _selectedIndex == 1 ? Colors.white : Colors.white70,
                textStyle: theme.textTheme.labelSmall?.copyWith(
                  color: _selectedIndex == 1 ? Colors.white : Colors.white70,
                ),
                semanticLabel: 'My Courses',
              ),
              GButton(
                icon: Icons.star_purple500_outlined,
                text: "Favourite",
                iconColor: _selectedIndex == 2 ? Colors.white : Colors.white70,
                textStyle: theme.textTheme.labelSmall?.copyWith(
                  color: _selectedIndex == 2 ? Colors.white : Colors.white70,
                ),
                semanticLabel: 'Chat',
              ),
              GButton(
                leading: Image.asset('assets/gemini-color.png', height: 24),
                icon: Icons.smart_toy_rounded,
                text: "Gemini",
                iconColor: _selectedIndex == 3 ? Colors.white : Colors.white70,
                textStyle: theme.textTheme.labelSmall?.copyWith(
                  color: _selectedIndex == 3 ? Colors.white : Colors.white70,
                ),
                semanticLabel: 'Gemini AI',
              ),
              GButton(
                icon: Icons.settings,
                text: "Settings",
                iconColor: _selectedIndex == 4 ? Colors.white : Colors.white70,
                textStyle: theme.textTheme.labelSmall?.copyWith(
                  color: _selectedIndex == 4 ? Colors.white : Colors.white70,
                ),
                semanticLabel: 'Settings',
              ),
            ],
          ),
        ),
      ),
    ),
    floatingActionButton: (_selectedIndex == 1 && userRole == 'Teacher')
        ? FloatingActionButton(
            shape: const CircleBorder(),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.teacherDashboard);
            },
            backgroundColor: themeProvider.isDarkMode
                ? const Color.fromARGB(255, 70, 69, 69)
                : Colors.blue,
            child: const Icon(Icons.add_circle_rounded, color: Colors.white, size: 28),
          )
        : null,
    floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    extendBody: true,
    resizeToAvoidBottomInset: false,
  );
}
}