import 'package:flutter/material.dart';
import 'dart:math' as math;

class OnboardingIllustrations {
  // Screen 1: Welcome to CuddleCare - Pet owner with cat and dog in park
  static Widget welcomeIllustration({double size = 200}) {
    return ClipRRect(
      child: Image.asset(
        'assets/images/kittyy.png', // TODO: Replace with your image file
        height: size,
        width: size,
        fit: BoxFit.cover,
      ),
    );
  }

  // Screen 2: Choose a Service - Pet service icons
  static Widget servicesIllustration({double size = 200}) {
    return ClipRRect(
      child: Image.asset(
        'assets/images/dog.png',
        height: size,
        width: size,
        fit: BoxFit.cover,
      ),
    );
  }

  // Screen 3: Book Appointments - Calendar and booking
  static Widget bookingIllustration({double size = 200}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: Image.asset(
        'assets/images/calander.png',
        height: size,
        width: size,
        fit: BoxFit.cover,
      ),
    );
  }

  // New cat illustration
  static Widget catIllustration({double size = 200}) {
    return Image.asset(
      'assets/images/kittyy.png',
      height: size,
      width: size,
    );
  }
}
