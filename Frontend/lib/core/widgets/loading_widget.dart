import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../app/theme/app_theme.dart';

class LoadingWidget extends StatelessWidget {
  final String message;

  const LoadingWidget({super.key, this.message = 'Loading...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SpinKitCubeGrid(
            color: AppColors.primary,
            size: 45.0,
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
