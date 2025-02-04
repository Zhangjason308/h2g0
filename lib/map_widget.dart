import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:h2g0/models/Place.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'credentials.dart';


class MapWidget extends StatefulWidget {
  const MapWidget(
    {super.key
    });

  @override
  State<MapWidget> createState() => _MapWidget();
}

Widget buildMap(AnimatedMapController animatedMapController) {
  return FlutterMap(
    mapController: animatedMapController.mapController,
    options: MapOptions(
      initialCenter: LatLng(45.424721, -75.695000), // Center the map over Ottawa
      initialZoom: 14,
    ),
    children: [
      TileLayer( // Bring your own tiles
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // For demonstration only
        userAgentPackageName: 'com.example.app', // Add your app identifier
        tileProvider: CancellableNetworkTileProvider(),
        // And many more recommended properties!
      ),
      RichAttributionWidget(
        alignment: AttributionAlignment.bottomLeft, // Include a stylish prebuilt attribution widget that meets all requirments
        attributions: [
          TextSourceAttribution(
            'OpenStreetMap contributors',
            onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')), // (external)
          ),
          // Also add images...
        ],
      ),
    ],
        );
}

class _MapWidget extends State<MapWidget> with TickerProviderStateMixin{
  
  late final _animatedMapController = AnimatedMapController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
    curve: Curves.easeInOutSine,
    cancelPreviousAnimations: true, // Default to false
    );

  final _controller = FloatingSearchBarController();
  List<Place> placesList = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void zoomMap() {
    _animatedMapController.centerOnPoint(
      LatLng(45.424721, -75.695000), zoom: 16
    );
  }
  

  @override
  Widget build(BuildContext context) {
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    String selectedID;
    
    void getResults(String input) async{

      String baseURL='https://maps.googleapis.com/maps/api/place/autocomplete/json';
      String type = 'geocode';
      String location = '45.424721 -75.695000';
      String radius = '5000';
      //TODO Add session token

      String request = '$baseURL?input=$input&key=$PLACES_API_KEY&type=$type&location=$location&radius=$radius';
      Response response = await Dio().get(request);

      final predictions = response.data['predictions'];

      print(predictions);

      List<Place> _displayResults = [];

      for (var i = 0; i < predictions.length; i++) {
        String address = predictions[i]['description'];
        String placeid = predictions[i]['place_id'];
        if (!address.contains("NOT")) {
          _displayResults.add(Place(address, placeid));
        }
      }

      setState(() {
        placesList = _displayResults;
      });
    }

    void getLatLng(String PLACE_ID, String ADDRESS) async {
      String baseURL='https://maps.googleapis.com/maps/api/place/details/json';
      String fields = 'geometry';

      String request = '$baseURL?input=$ADDRESS&placeid=$PLACE_ID&fields=$fields&key=$PLACES_API_KEY';
      Response response = await Dio().get(request);

      final result = response.data['result']['geometry']['location'];

      double lat = result['lat'] as double;
      double lng = result['lng'] as double;
      
      _animatedMapController.centerOnPoint(LatLng(lat, lng), zoom: 16);
    }

    return Scaffold(
      body: Stack(
        children: [
          buildMap(_animatedMapController),
          FloatingSearchBar(
            controller: _controller,
            hint: 'Search...',
            scrollPadding: const EdgeInsets.only(top: 16, bottom: 56),
            transitionDuration: const Duration(milliseconds: 800),
            transitionCurve: Curves.easeInOut,
            physics: const BouncingScrollPhysics(),
            axisAlignment: isPortrait ? 0.0 : -1.0,
            openAxisAlignment: 0.0,
            width: isPortrait ? 600 : 500,
            textInputAction: TextInputAction.next,
            clearQueryOnClose: false,
            onFocusChanged: (isFocused) => {
              if (!isFocused) {
                setState(() {
                  placesList = [];
                })
              }
            },
            debounceDelay: const Duration(milliseconds: 500),
            onSubmitted: (query) {
              print(query);
              placesList = [];
              _controller.close();
            },
            onQueryChanged: (query) {
              if (query != '') {
                getResults(query);
              } else {
                setState(() {
                  placesList = [];
                });
              }
            },
            // Specify a custom transition to be used for
            // animating between opened and closed stated.
            transition: CircularFloatingSearchBarTransition(),
            actions: [
              FloatingSearchBarAction(
                showIfOpened: false,
                child: CircularButton(
                  icon: const Icon(Icons.place),
                  onPressed: () {},
                ),
              ),
              FloatingSearchBarAction.searchToClear(
                showIfClosed: false,
              ),
            ],
            builder: (context, transition) {
              if (placesList.isEmpty) {
                return Container();
              }
              else {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Material(
                    color: Colors.white,
                    elevation: 4.0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: placesList.map((place) {
                        return ListTile(
                          title: Text(place.address),
                          onTap: () {
                            selectedID = place.placeid;
                            _controller.query = place.address;
                            _controller.close();
                            getLatLng(selectedID, place.address);
                          }
                        );
                      }).toList(),
                    ),
                  ),
                );
              }
            },
          )
        ]
      ),
      floatingActionButton: FloatingActionButton(onPressed: () {
        zoomMap();
      })
     );
  }
}