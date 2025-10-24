import 'package:flutter/material.dart';
import 'package:studypro/components/dash_bard_card.dart';
import 'package:studypro/routes/app_routes.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});



  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Teacher Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            DashboardCard(
              iconPath: 'assets/online-education.png',
              title: 'My Courses',
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.currentTeacherCourse);
              },
            ),
            DashboardCard(
              iconPath: 'assets/add-button.png',
              title: 'Create Course',
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.createCourse);
              },
            ),
          
          ],
        ),
      ),
    );
  }
}