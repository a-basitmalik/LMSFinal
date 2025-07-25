import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:newapp/admin/themes/theme_colors.dart';
import 'package:newapp/admin/themes/theme_extensions.dart';
import 'package:newapp/admin/themes/theme_text_styles.dart';
import 'AdminDashboard.dart';
import 'AdminRoutes.dart';
class AdminMain extends StatelessWidget {
  final String userId;

  const AdminMain({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: AdminColors.primaryAccent,
          secondary: AdminColors.secondaryAccent,
          surface: AdminColors.primaryBackground,
        ),
      ),
      home: SelectCampus(userId: userId),
      onGenerateRoute: AdminRoutes.generateRoute,
    );
  }
}

class SelectCampus extends StatefulWidget {
  final String userId;

  const SelectCampus({Key? key, required this.userId}) : super(key: key);

  @override
  _SelectCampusState createState() => _SelectCampusState();
}

class _SelectCampusState extends State<SelectCampus> {
  final String baseUrl = "http://193.203.162.232:5050";
  List<Map<String, dynamic>> campuses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCampusesFromDatabase();
  }

  Future<void> loadCampusesFromDatabase() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/campus/get_campuses'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          campuses = data.map((item) => item as Map<String, dynamic>).toList();
          isLoading = false;
        });
      } else {
        showErrorToast("Failed to load campuses: ${response.statusCode}");
      }
    } catch (e) {
      showErrorToast("Failed to load campuses");
    }
  }

  void showErrorToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AdminColors.dangerAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
    setState(() {
      isLoading = false;
    });
  }

  void navigateToDashboard(int campusID, String campusName) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => AdminDashboard(
          campusID: campusID,
          campusName: campusName,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  Widget buildCampusCard(Map<String, dynamic> campus) {
    return GlassCard(
      borderRadius: 16,
      borderColor: AdminColors.primaryAccent.withOpacity(0.3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => navigateToDashboard(campus['CampusID'], campus['CampusName']),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: AdminColors.primaryAccent.toCircleDecoration(size: 48),
                  child: Icon(
                    Icons.school_outlined,
                    color: AdminColors.primaryAccent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campus['CampusName'],
                        style: AdminTextStyles.cardTitle.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${campus['CampusID']}',
                        style: AdminTextStyles.cardSubtitle,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AdminColors.primaryAccent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Select Campus',
          style: AdminTextStyles.sectionHeader.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AdminColors.primaryAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(
          child: CircularProgressIndicator(
            color: AdminColors.primaryAccent,
          ),
        )
            : ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: campuses.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: buildCampusCard(campuses[index]),
            );
          },
        ),
      ),
    );
  }
}