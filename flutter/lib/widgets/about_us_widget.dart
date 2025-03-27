import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AboutUsWidget extends StatelessWidget {
  const AboutUsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryLight,
                  AppTheme.primaryDark,
                ],
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              children: [
                Text(
                  'About H2G0',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Making public washrooms accessible for everyone',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Our Mission',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.tabText,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'H2G0 is dedicated to making public washrooms more accessible and easier to find for everyone. We believe that access to clean, safe washroom facilities is a basic necessity, and our mission is to help people locate them quickly and easily.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    height: 1.6,
                    color: AppTheme.tabText.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Meet Our Team',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.tabText,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FutureBuilder(
                    future: precacheImage(AssetImage('assets/images/team.png'), context),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        print('Error loading team image: ${snapshot.error}');
                        return Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.grey[300],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported, size: 50, color: Colors.grey[600]),
                              const SizedBox(height: 8),
                              Text('Unable to load team image',
                                style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        );
                      }
                      return Image.asset(
                        'assets/images/team.png',
                        width: double.infinity,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'The H2G0 Team at Carleton University',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.tabText.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Text(
                  'What We Do',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.tabText,
                  ),
                ),
                const SizedBox(height: 12),
                _buildFeatureCard(
                  icon: Icons.map,
                  title: 'Interactive Mapping',
                  description: 'Find nearby washrooms with our easy-to-use interactive map.',
                ),
                _buildFeatureCard(
                  icon: Icons.accessibility_new,
                  title: 'Accessibility Information',
                  description: 'Detailed accessibility information for each location.',
                ),
                _buildFeatureCard(
                  icon: Icons.people,
                  title: 'Community Driven',
                  description: 'Powered by community contributions and real-time updates.',
                ),
                const SizedBox(height: 32),
                Text(
                  'Get Involved',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.tabText,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Help us make washrooms more accessible for everyone by contributing to our database and sharing your experiences. Together, we can create a more inclusive community.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    height: 1.6,
                    color: AppTheme.tabText.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.tabBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 32,
            color: AppTheme.primaryLight,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.tabText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.tabText.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 