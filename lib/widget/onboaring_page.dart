import 'package:flutter/material.dart';

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath; // Path to the image

  const OnboardingPage({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 48, 12, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Padding(
            padding:
                const EdgeInsets.only(right: 32.0), // Add padding to the right
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 4,
                ), // Small space between text and image
                Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  height: 60, // Adjust this value to match your text height
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(
                fontSize: 16, color: Color.fromRGBO(41, 44, 41, 1)),
          ),
        ],
      ),
    );
  }
}
