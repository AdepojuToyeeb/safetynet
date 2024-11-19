import 'package:flutter/material.dart';

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final textScale = MediaQuery.of(context).textScaleFactor;

    final double baseTitleSize = 42.0;
    final double baseDescriptionSize = 16.0;
    final double titleFontSize = (baseTitleSize * textScale).clamp(24.0, 52.0);
    final double descriptionFontSize = (baseDescriptionSize * textScale).clamp(14.0, 18.0);
    final double imageHeight = screenHeight * 0.08;
    final double horizontalPadding = screenWidth * 0.03;

    return LayoutBuilder(
      builder: (context, constraints) {
        final adjustedImageHeight = imageHeight.clamp(40.0, 60.0);

        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            screenHeight * 0.06,
            horizontalPadding,
            0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.02),
              Padding(
                padding: EdgeInsets.only(right: horizontalPadding * 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                      ),
                    ),
                    SizedBox(width: horizontalPadding * 0.3),
                    Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      height: adjustedImageHeight,
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: descriptionFontSize,
                      color: const Color.fromRGBO(41, 44, 41, 1),
                      height: 1.5,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}