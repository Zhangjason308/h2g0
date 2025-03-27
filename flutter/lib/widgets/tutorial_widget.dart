import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../main.dart';

class TutorialPage {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;

  TutorialPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
  });
}

class TutorialWidget extends StatefulWidget {
  final bool isFirstLaunch;
  final VoidCallback onFinish;

  const TutorialWidget({
    super.key,
    required this.isFirstLaunch,
    required this.onFinish,
  });

  @override
  State<TutorialWidget> createState() => _TutorialWidgetState();
}

class _TutorialWidgetState extends State<TutorialWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final FocusNode _focusNode = FocusNode();

  final List<TutorialPage> _pages = [
    TutorialPage(
      title: 'Welcome to H2G0',
      description: 'Your personal guide to finding clean, accessible washrooms in your area.',
      icon: Icons.wc,
      iconColor: AppTheme.primaryLight,
    ),
    TutorialPage(
      title: 'Find Washrooms',
      description: 'Use the map to locate nearby washrooms. Tap on markers to see details and get directions.',
      icon: Icons.map,
      iconColor: AppTheme.primaryLight,
    ),
    TutorialPage(
      title: 'Submit Locations',
      description: 'Help others by submitting new washroom locations. Share details about accessibility and cleanliness.',
      icon: Icons.add_location_alt,
      iconColor: AppTheme.primaryLight,
    ),
    TutorialPage(
      title: 'Get Started',
      description: 'Ready to find your next washroom? Let\'s begin!',
      icon: Icons.check_circle,
      iconColor: AppTheme.primaryLight,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onFinish();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _nextPage();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _previousPage();
          }
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        AppTheme.tabBackground,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Icon(
                          _pages[index].icon,
                          size: 120,
                          color: _pages[index].iconColor,
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _pages[index].title,
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.tabText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            _pages[index].description,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: AppTheme.tabText.withOpacity(0.8),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? AppTheme.primaryLight
                              : AppTheme.primaryLight.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      children: [
                        if (_currentPage > 0)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: OutlinedButton(
                                onPressed: _previousPage,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primaryLight,
                                  side: BorderSide(color: AppTheme.primaryLight),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Previous',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryLight,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 