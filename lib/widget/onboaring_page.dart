import 'package:flutter/material.dart';
import 'package:safetynet/widget/custom_next_button.dart';
import 'package:safetynet/widget/page_indicator_widget.dart';

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath; // Path to the image
  final int currentPage;
  final String buttonText;
  final VoidCallback onPressed;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.buttonText,
    required this.onPressed,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12,32, 12, 96),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.only(
                  right: 32.0), // Add padding to the right
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            const SizedBox(height: 48),
            PageIndicator(
              totalPages: 3,
              currentPage: currentPage,
            ),
            const SizedBox(height: 48),
            // SizedBox(
            //     width: double.infinity,
            //     child: CustomNextButton(
            //       onPressed: onPressed,
            //       text: buttonText,
            //     )),
          ],
        ),
      ),
    );
  }
}
