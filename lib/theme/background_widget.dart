import 'package:flutter/material.dart';
import 'app_colors.dart';

class BackgroundWidget extends StatelessWidget {
  final Widget child;

  const BackgroundWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        // Luna warm cream background
        color: AppColors.background,
      ),
      child: SafeArea(child: child),
    );
  }
}
