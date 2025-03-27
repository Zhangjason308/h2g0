import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'map_widget.dart';
import 'widgets/app_bar.dart';
import 'widgets/tutorial_widget.dart';
import 'widgets/about_us_widget.dart';
import 'widgets/contact_widget.dart';
import 'theme/app_theme.dart';

const String apiKey = String.fromEnvironment('PLACES_API_KEY');
const String graphapikey = String.fromEnvironment('GRAPHHOPPER_API_KEY');
String get apiUrl => const String.fromEnvironment('API_URL', defaultValue: 'http://localhost:5001');
const String _firstLaunchKey = 'is_first_launch';

void main() async {
  await dotenv.load(fileName: "assets/.env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'H2G0',
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: AppTheme.primaryLight,
          secondary: AppTheme.primaryDark,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String selectedTab = 'Map';
  bool _showTutorial = false;
  final String? placesAPIKey= dotenv.env['PLACES_API_KEY'];
  final String? graphapikey = dotenv.env['GRAPHHOPPER_API_KEY'];
  final String? apiUrl = dotenv.env['API_URL'];

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool(_firstLaunchKey) ?? true;
    
    if (isFirstLaunch) {
      setState(() {
        _showTutorial = true;
      });
      await prefs.setBool(_firstLaunchKey, false);
    }
  }

  Future<Map<String, dynamic>> fetchData() async {
    //final String url = apiUrl.startsWith('http') ? apiUrl : 'http://$apiUrl';
    // final Uri uri = Uri.parse('$apiUrl/api/locations');
    try {
      //final response = await http.get(Uri.parse('$apiUrl/locations'));
      final response =
          await http.get(Uri.parse(apiUrl!));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to load data - 1');
      }
    } catch (error) {
      print('Error fetching data: $error');
      throw Exception('Failed to load data - 2');
    }
  }

  Widget _buildBody(String tab, List washroomLocations, List waterFountainLocations) {
    switch (tab) {
      case 'Map':
        return MapWidget(
          placesAPIKey: placesAPIKey,
          graphapikey: graphapikey,
          washroomLocations: washroomLocations,
          waterFountainLocations: waterFountainLocations, // Add empty list for now since we're not using water fountains yet
        );
      case 'Tutorial':
        return TutorialWidget(
          isFirstLaunch: false,
          onFinish: () {
            setState(() {
              selectedTab = 'Map';
            });
          },
        );
      case 'Submission Form':
        return Center(child: Text("Submission Form Page"));
      case 'About Us':
        return const AboutUsWidget();
      case 'Contact':
        return const ContactWidget();
      default:
        return Center(child: Text("Unknown Page"));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showTutorial) {
      return TutorialWidget(
        isFirstLaunch: true,
        onFinish: () {
          setState(() {
            _showTutorial = false;
            selectedTab = 'Map';
          });
        },
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (selectedTab != 'Map') {
          setState(() {
            selectedTab = 'Map';
          });
          return false;
        }
        return true;
      },
      child: FutureBuilder<Map<String, dynamic>>(
        future: fetchData(),
        builder: (context, snapshot) {
          Widget body;

          if (snapshot.connectionState == ConnectionState.waiting) {
            body = const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            body = Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final washroomLocations = snapshot.data!['washroomLocations'];
            final waterFountainLocations = snapshot.data!['fountainLocations'];
            body = _buildBody(selectedTab, washroomLocations, waterFountainLocations);
          } else {
            body = const Center(child: Text('No data available'));
          }

          return Scaffold(
            appBar: ResponsiveAppBar(
              onTabSelected: (label) {
                setState(() {
                  selectedTab = label;
                });
              },
            ),
            endDrawer: MediaQuery.of(context).size.width <= 600
                ? Drawer(
                    child: Container(
                      decoration: AppTheme.appBarGradient,
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          DrawerHeader(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('H2G0', style: AppTheme.appBarTitle),
                                const SizedBox(height: 8),
                                Text(
                                  'Navigation Menu',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...['Map', 'Tutorial', 'Submission Form', 'About Us', 'Contact'].map((label) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: AppTheme.tabBackground,
                              ),
                              child: ListTile(
                                title: Text(
                                  label,
                                  style: AppTheme.tabTextStyle,
                                ),
                                leading: Icon(
                                  _getIconForLabel(label),
                                  color: AppTheme.tabText,
                                ),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  setState(() {
                                    selectedTab = label;
                                  });
                                },
                                hoverColor: AppTheme.primaryLight.withOpacity(0.1),
                                splashColor: AppTheme.primaryLight.withOpacity(0.2),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  )
                : null,
            body: body,
          );
        },
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label) {
      case 'Map':
        return Icons.map;
      case 'Tutorial':
        return Icons.help_outline;
      case 'Submission Form':
        return Icons.add_location_alt;
      case 'About Us':
        return Icons.info_outline;
      case 'Contact':
        return Icons.contact_mail;
      default:
        return Icons.circle;
    }
  }
}
