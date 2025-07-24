import 'package:flutter/material.dart';
import '../utils/theme.dart';

class BaseScreen extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool extendBodyBehindAppBar;
  final Widget? floatingActionButton;
  final bool useSafeArea;

  const BaseScreen({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.showBackButton = true,
    this.extendBodyBehindAppBar = false,
    this.floatingActionButton,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        leading: showBackButton
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        )
            : null,
        actions: actions,
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryBackground,
              AppColors.secondaryBackground,
            ],
          ),
        ),
        child: useSafeArea ? SafeArea(child: body) : body,
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}