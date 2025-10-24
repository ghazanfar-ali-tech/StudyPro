import 'package:flutter/material.dart';

import 'package:studypro/routes/app_routes.dart';
import 'package:studypro/views/auth_screens/forgot_password_screen.dart';
import 'package:studypro/views/auth_screens/login_screen.dart';
import 'package:studypro/views/auth_screens/sign_up_screen.dart';
import 'package:studypro/views/favourite_course/fav_course_screen.dart';
import 'package:studypro/views/course_creation_screens/course_creation.dart';
import 'package:studypro/views/course_creation_screens/upload_video_playlist.dart';
import 'package:studypro/views/main_page_screen.dart';
import 'package:studypro/views/settings.dart';
import 'package:studypro/views/splash_screen.dart';
import 'package:studypro/views/teacher_dashboard/current_teacher_courses.dart';
import 'package:studypro/views/teacher_dashboard/dashboard_screen.dart';
import 'package:studypro/views/view_course_screen.dart';


class AppRouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) =>  SplashScreen());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.signup:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case AppRoutes.mainPage:
        return MaterialPageRoute(builder: (_) => const MainPageScreen());  
      case AppRoutes.forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());  
      case AppRoutes.setting:
        return MaterialPageRoute(builder: (_) => const SettingScreen());
      case AppRoutes.createCourse:
        return MaterialPageRoute(builder: (_) => const CourseCreationScreen());
      case AppRoutes.uploadPlaylist:
        return MaterialPageRoute(builder: (_) => const UploadVideoPlaylistScreen());
      case AppRoutes.viewCourse:
        return MaterialPageRoute(builder: (_) => const ViewCourseScreen());
      case AppRoutes.teacherDashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case AppRoutes.currentTeacherCourse:
        return MaterialPageRoute(builder: (_) => const CurrentTeacherCourse());
      case AppRoutes.chatList:
        return MaterialPageRoute(builder: (_) => const FavoriteCoursesScreen());

      default:
        return MaterialPageRoute(builder: (_) => const MainPageScreen());
    }
  }
}
