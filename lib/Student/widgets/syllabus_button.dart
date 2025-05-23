import 'package:flutter/material.dart';
import '../utils/app_design_system.dart';

class SyllabusButton extends StatelessWidget {
  final String subjectName;
  final VoidCallback onPressed;

  const SyllabusButton({
    super.key,
    required this.subjectName,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: AppDesignSystem.defaultBorderRadius, // Fixed line
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            subjectName,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const Icon(Icons.picture_as_pdf, color: Colors.red),
        ],
      ),
    );
  }
}
