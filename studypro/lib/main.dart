import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:studypro/providers/auth_providers/login_provider.dart';
import 'package:studypro/providers/auth_providers/signup_providers.dart';
import 'package:studypro/providers/chat_providers/chat_provider.dart';
import 'package:studypro/providers/course_provider.dart';
import 'package:studypro/providers/fav_provider.dart';
import 'package:studypro/providers/feed_back_provider.dart';
import 'package:studypro/providers/playlist_provider.dart';
import 'package:studypro/providers/progress_provider.dart';
import 'package:studypro/providers/review_provider.dart';
import 'package:studypro/providers/theme_provider.dart';
import 'package:studypro/providers/userProfileProvider.dart';
import 'package:studypro/routes/app_route_generator.dart';
import 'package:studypro/routes/app_routes.dart';
import 'package:studypro/views/Gemini_AI/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "your api key",
      appId: " your app id",
      messagingSenderId: "your messenger id",
      projectId: "you project id",
    ),
  );
  Gemini.init(apiKey: geminiApiKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => SignUpProvider()),
        ChangeNotifierProvider(create: (_) => PlaylistProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => FeedbackProvider()), 
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
       
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'StudyPro',
            localizationsDelegates: const [
              FlutterQuillLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''),
            ],
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            darkTheme: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
            ),
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRouteGenerator.generateRoute,
          );
        },
      ),
    );
  }
}