import 'package:flutter/material.dart';
import 'package:safetynet/screens/auth/login_or_signup_screen.dart';
import 'package:safetynet/widget/custom_next_button.dart';
import 'package:safetynet/widget/onboaring_page.dart';
import 'package:safetynet/widget/page_indicator_widget.dart';

class OnboardingScreens extends StatefulWidget {
  const OnboardingScreens({super.key});

  @override
  State<OnboardingScreens> createState() => _OnboardingScreensState();
}

class _OnboardingScreensState extends State<OnboardingScreens> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  void _nextPage() {
    if (_pageController.page! < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Navigate to the main app screen or perform final action
      print('Onboarding completed!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              // Background image
              Image.asset(
                'assets/images/backgroud.png', // Replace with your image asset
                height: MediaQuery.of(context).size.height *
                    0.305, // Adjust the height
                width: double.infinity,
                fit: BoxFit.cover,
              ),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: CustomPaint(
                  size: Size(MediaQuery.of(context).size.width, 50),
                  painter: SlantLinesPainter(),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 64,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              children: [
                OnboardingPage(
                  title: 'Welcome to SafetyNet',
                  description:
                      'Stay safe with quick emergency alerts and real-time collaboration to get help just when you need it.',
                  imagePath: 'assets/images/onboarding1.png',
                  buttonText: 'Next',
                  onPressed: _nextPage,
                  currentPage: _currentPage,
                ),
                OnboardingPage(
                  title: 'Activate Alerts Quickly',
                  description:
                      'Just a few taps to activate alerts. Your emergency contacts get notified instantly.',
                  imagePath: "assets/images/onboarding2.png",
                  buttonText: 'Next',
                  onPressed: _nextPage,
                  currentPage: _currentPage,
                ),
                OnboardingPage(
                  title: 'Emergency Contacts',
                  description:
                      'Manage and update your emergency contacts for quick access in an emergency.',
                  imagePath: "assets/images/onboarding3.png",
                  buttonText: 'Get Started',
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SafetynetLoginScreen(),
                      ), // Push a new screen
                    );
                  },
                  currentPage: _currentPage,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 48),
            child: CustomNextButton(
              onPressed: _currentPage < 2
                  ? _nextPage
                  : () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SafetynetLoginScreen(),
                        ), // Push a new screen
                      );
                    },
              text: _currentPage < 2 ? "Next" : "Get Started",
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class SlantLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final darkPaint = Paint()
      ..color = const Color.fromRGBO(74, 76, 75, 1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9;

    final lightPaint = Paint()
      ..color = const Color.fromRGBO(25, 118, 210, 1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;

    // Reduce the vertical distance the lines travel
    double verticalTravel =
        size.height * 0.3; // Adjust this value to change the slant

    // First dark line
    canvas.drawLine(
      Offset(0, size.height + 16),
      Offset(size.width - 110, size.height - verticalTravel - 16),
      darkPaint,
    );

    // Light line
    canvas.drawLine(
      Offset(size.width * 0.34, size.height + 16),
      Offset(size.width, size.height - verticalTravel - 10),
      lightPaint,
    );

    // Second dark line
    canvas.drawLine(
      Offset(size.width * 0, size.height + 60),
      Offset(size.width - 105, size.height - verticalTravel + 28),
      darkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
