import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'map_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> main() async {
  await dotenv.load(fileName: ".env"); // First Load dotenv  in main function
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 72, 140, 230)),
        useMaterial3: true,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  Future<Map<String, dynamic>> fetchData() async {
    //final String? apiUrl = dotenv.env['API_URL'];

    try {
      //final response = await http.get(Uri.parse('$apiUrl/locations'));
      final response =
          await http.get(Uri.parse('http://localhost:5000/locations'));
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

  @override
  Widget build(BuildContext context) {
    final String? apikey = dotenv.env['PLACES_API_KEY'];

    //return MapWidget(placesAPIKey: apikey);

    return Scaffold(
      appBar: AppBar(title: const Text("Washroom Map")),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final washroomLocations = snapshot.data!['washroomLocations'];
            final waterFountainLocations = snapshot.data!['fountainLocations'];

            // Return the MapWidget with fetched data
            return MapWidget(
              placesAPIKey: apikey, // Pass the API key to MapWidget
              washroomLocations: washroomLocations,
              waterFountainLocations: waterFountainLocations,
            );
          } else {
            // If no data available, show a fallback message
            return Center(child: Text('No data available'));
          }
        },
      ),
    );
  }
}
