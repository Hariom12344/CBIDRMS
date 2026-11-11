import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds & Surface
  static const Color background = Color(0xFF0F172A);      // Slate 900
  static const Color surface = Color(0xFF1E293B);         // Slate 800
  static const Color surfaceLight = Color(0xFF334155);    // Slate 700
  static const Color cardBackground = Color(0xFF1E293B);  // Slate 800
  
  // Accents
  static const Color primary = Color(0xFF6366F1);          // Indigo 500
  static const Color primaryHover = Color(0xFF4F46E5);     // Indigo 600
  static const Color secondary = Color(0xFF06B6D4);        // Cyan 500
  
  // Status & Feedback
  static const Color success = Color(0xFF10B981);          // Emerald 500
  static const Color error = Color(0xFFEF4444);            // Rose 500
  static const Color warning = Color(0xFFF59E0B);          // Amber 500
  
  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);       // Slate 50
  static const Color textSecondary = Color(0xFF94A3B8);     // Slate 400
  static const Color textMuted = Color(0xFF64748B);         // Slate 500

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF020617)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
