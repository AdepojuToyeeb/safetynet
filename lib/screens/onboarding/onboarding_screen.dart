import 'package:flutter/material.dart';
import 'package:safetynet/screens/auth/login_or_signup_screen.dart';
import 'package:safetynet/widget/custom_next_button.dart';
import 'package:safetynet/widget/onboaring_page.dart';
import 'package:safetynet/widget/page_indicator_widget.dart';

// Models
class OnboardingContent {
  final String title;
  final String description;
  final String imagePath;
  final String buttonText;

  const OnboardingContent({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.buttonText,
  });
}

// Constants
class OnboardingData {
  static const List<OnboardingContent> pages = [
    OnboardingContent(
      title: 'Welcome to SafetyNet',
      description:
          'Stay safe with quick emergency alerts and real-time collaboration to get help just when you need it.',
      imagePath: 'assets/images/onboarding1.png',
      buttonText: 'Next',
    ),
    OnboardingContent(
      title: 'Activate Alerts Quickly',
      description:
          'Just a few taps to activate alerts. Your emergency contacts get notified instantly.',
      imagePath: 'assets/images/onboarding2.png',
      buttonText: 'Next',
    ),
    OnboardingContent(
      title: 'Emergency Contacts',
      description:
          'Manage and update your emergency contacts for quick access in an emergency.',
      imagePath: 'assets/images/onboarding3.png',
      buttonText: 'Get Started',
    ),
  ];
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController()..addListener(_onPageChanged);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  void _onPageChanged() {
    if (_pageController.page != null) {
      final newPage = _pageController.page!.round();
      if (newPage != _currentPage) {
        setState(() => _currentPage = newPage);
        _animationController.reset();
        _animationController.forward();
      }
    }
  }

  Future<void> _nextPage() async {
    if (_currentPage < OnboardingData.pages.length - 1) {
      await _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SafetynetLoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    return Scaffold(
      backgroundColor: Colors.white,  
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(constraints),
              const SizedBox(height: 32),
              Expanded(child: _buildPageView(isLandscape, constraints)),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth * 0.04,
                ),
                child: PageIndicator(
                  totalPages: OnboardingData.pages.length,
                  currentPage: _currentPage,
                ),
              ),
              _buildFooter(constraints),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BoxConstraints constraints) {
    final headerHeight =
        constraints.maxHeight * (constraints.maxWidth > 600 ? 0.25 : 0.3);

    return SizedBox(
      height: headerHeight,
      child: Stack(
        children: [
          Hero(
            tag: 'onboarding_background',
            child: Image.asset(
              'assets/images/backgroud.png',
              height: headerHeight,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(constraints.maxWidth, headerHeight * 0.2),
              painter: SlantLinesPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageView(bool isLandscape, BoxConstraints constraints) {
    return PageView.builder(
      controller: _pageController,
      itemCount: OnboardingData.pages.length,
      itemBuilder: (context, index) {
        final content = OnboardingData.pages[index];
        return Column(
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.02,
                ),
                child: OnboardingPage(
                  title: content.title,
                  description: content.description,
                  imagePath: content.imagePath,
                ),
              ),
            ),
            SizedBox(height: constraints.maxHeight * 0.02),
          ],
        );
      },
    );
  }

  Widget _buildFooter(BoxConstraints constraints) {
    return Container(
      padding: EdgeInsets.only(
        left: constraints.maxWidth * 0.05,
        right: constraints.maxWidth * 0.05,
        bottom: constraints.maxHeight * 0.03,
        top: constraints.maxHeight * 0.02,
      ),
      child: CustomNextButton(
        onPressed: _nextPage,
        text: OnboardingData.pages[_currentPage].buttonText,
        enabled: true,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

class SlantLinesPainter extends CustomPainter {
  static const _darkColor = Color.fromRGBO(74, 76, 75, 1);
  static const _lightColor = Color.fromRGBO(25, 118, 210, 1);

  @override
  void paint(Canvas canvas, Size size) {
    final darkPaint = Paint()
      ..color = _darkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    final lightPaint = Paint()
      ..color = _lightColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final verticalTravel = size.height * 0.3;

    // Draw lines with smooth endings
    _drawSlantLine(
      canvas,
      start: Offset(0, size.height + 16),
      end: Offset(size.width - 110, size.height - verticalTravel - 16),
      paint: darkPaint,
    );

    _drawSlantLine(
      canvas,
      start: Offset(size.width * 0.34, size.height + 16),
      end: Offset(size.width, size.height - verticalTravel - 10),
      paint: lightPaint,
    );

    _drawSlantLine(
      canvas,
      start: Offset(0, size.height + 60),
      end: Offset(size.width - 105, size.height - verticalTravel + 28),
      paint: darkPaint,
    );
  }

  void _drawSlantLine(
    Canvas canvas, {
    required Offset start,
    required Offset end,
    required Paint paint,
  }) {
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}