import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:newapp/Student/screens/home_screen.dart';
import 'package:newapp/Student/providers/theme_provider.dart';

class StudentMain extends StatelessWidget {
  final String userId;

  const StudentMain({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Builder(
        builder: (context) {
          final themeProvider = Provider.of<ThemeProvider>(context);
          return MaterialApp(
            title: 'Student Dashboard',
            theme: themeProvider.currentTheme,
            home: HomeScreen(userId: userId),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
