import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:h2g0/models/place.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'bottom_bar.dart';

class MapWidget extends StatefulWidget {
  final String? placesAPIKey;
  final List washroomLocations;
  //final List waterFountainLocations;

  const MapWidget(
      {super.key,
      required this.placesAPIKey,
      required this.washroomLocations});
      //required this.waterFountainLocations});

  @override
  State<MapWidget> createState() => _MapWidget();
}

Widget buildMap(AnimatedMapController mapcontroller, BuildContext context, List<Marker> markers, bool posAdded, Function(Map<String, dynamic>) onPinTap, Map<LatLng, Map<String, dynamic>> markerMetadata,) {
  final theme = Theme.of(context);

  return FlutterMap(
    mapController: mapcontroller.mapController,
    options: MapOptions(
      initialCenter:
          LatLng(45.424721, -75.695000), // Center the map over Ottawa
      initialZoom: 14,
    ),
    children: [
      TileLayer(
        // Bring your own tiles
        urlTemplate:
            'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // For demonstration only
        userAgentPackageName: 'com.h2g0.app', // Add your app identifier
        tileProvider: CancellableNetworkTileProvider(),
        // And many more recommended properties!
      ),

      MarkerLayer(
        markers: markers,
     ),

      CurrentLocationLayer(
        alignPositionOnUpdate: AlignOnUpdate.always,
        alignDirectionOnUpdate: AlignOnUpdate.never,
      ),
      Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: FloatingActionButton(
              backgroundColor: theme.colorScheme.primary,
              onPressed: () {
                mapcontroller.centerOnPoint(LatLng(45.424721, -75.695000),
                    zoom: 16);
              },
              child: Icon(
                Icons.my_location,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          )),
      RichAttributionWidget(
        alignment: AttributionAlignment
            .bottomLeft, // Include a stylish prebuilt attribution widget that meets all requirments
        attributions: [
          TextSourceAttribution(
            'OpenStreetMap contributors',
            onTap: () => launchUrl(
                Uri.parse('https://openstreetmap.org/copyright')), // (external)
          ),
          // Also add images...
        ],
      ),
    ],
  );
}

class _MapWidget extends State<MapWidget> with TickerProviderStateMixin {

  final Map<LatLng, Map<String, dynamic>> _markerMetadata = {};
  final _controller = FloatingSearchBarController();
  List<Place> placesList = [];

  final DraggableScrollableController _bottomSheetController = DraggableScrollableController();
  bool _isBottomSheetVisible = false;

  final List<Marker> _markers = [];
  bool _posAdded = false;

  Map<String, dynamic> _selectedMetadata = {
    'name': 'Select a location',
    'address': 'Tap a marker to see details',
  };

  late final _animatedMapController = AnimatedMapController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
    curve: Curves.easeInOutSine,
    cancelPreviousAnimations: true, // Default to false
  );

  void _handlePinTap(Map<String, dynamic> metadata) {
  setState(() {
    _selectedMetadata = metadata;
    _isBottomSheetVisible = true;
  });

  Future.delayed(Duration(milliseconds: 100), () {
    _bottomSheetController.animateTo(
      0.3,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  });
}




  @override
void dispose() {
  _controller.dispose();
  _bottomSheetController.dispose();
  super.dispose();
}

@override
void initState() {
  super.initState();

  setState(() {
    _markers.clear();
    
    for (var location in widget.washroomLocations) {
      double lat = (location['Y_COORDINATE'] ?? 0.0) as double; 
      double lng = (location['X_COORDINATE'] ?? 0.0) as double; 
      
      LatLng position = LatLng(lat, lng);

      Map<String, dynamic> metadata = {
        'name': location['NAME'],
        'address': location['ADDRESS'],
        'telephone': location['REPORT_TELEPHONE'],
        'hours monday open': location['HOURS_MONDAY_OPEN'],
        'hours tuesday open': location['HOURS_TUESDAY_OPEN'],
        'hours wednesday open': location['HOURS_WEDNESDAY_OPEN'],
        'hours thursday open': location['HOURS_THURSDAY_OPEN'],
        'hours friday open': location['HOURS_FRIDAY_OPEN'],
        'hours saturday open': location['HOURS_SATURDAY_OPEN'],
        'hours sunday open': location['HOURS_SUNDAY_OPEN'],
      };

      _markerMetadata[position] = metadata;
      
      _markers.add(
        Marker(
          width: 40,
          height: 40,
          point: LatLng(lat, lng),
          child: GestureDetector(
            onTap: () {
              _handlePinTap(_markerMetadata[position]!);
            },
            child: const Icon(
              Icons.wc, // Washroom icon
              color: Colors.blue,
              size: 40,
            ),
          ),
        ),
      );
    }
 
  });
}



  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    String? selectedID;
    String? apiKey = widget.placesAPIKey;

    void addMarker(LatLng coordinates) {
  if (_posAdded) {
    setState(() {
      _markers.removeLast();
    });
  }

  _markerMetadata[coordinates] = {
    'name': 'Searched Location',
    'address': 'Searched Address'
  };

  setState(() {
    _markers.add(
      Marker(
        width: 40,
        height: 40,
        point: coordinates,
        child: GestureDetector(
          onTap: () {
            _handlePinTap(_markerMetadata[coordinates]!);
          },
          child: const Icon(
            Icons.location_pin,
            color: Colors.red,
            size: 40,
          ),
        ),
      ),
    );
  });
}


    

    void getResults(String input) async {
      String baseURL =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json';
      String type = 'geocode';
      String location = '45.424721 -75.695000';
      String radius = '5000';
      //TODO Add session token

      String request =
          '$baseURL?input=$input&key=$apiKey&type=$type&location=$location&radius=$radius';

      Response response = await Dio().get(request);

      final predictions = response.data['predictions'];

      List<Place> displayResults = [];

      for (var i = 0; i < predictions.length; i++) {
        String address = predictions[i]['description'];
        String placeid = predictions[i]['place_id'];
        if (!address.contains("NOT")) {
          displayResults.add(Place(address, placeid));
        }
      }

      setState(() {
        placesList = displayResults;
      });
    }

    void getLatLng(String placeId, String address) async {
  if (placeId.isEmpty) {
    return;
  }

  String baseURL = 'https://maps.googleapis.com/maps/api/place/details/json';
  String fields = 'geometry';

  String request = '$baseURL?placeid=$placeId&fields=$fields&key=$apiKey';
  Response response = await Dio().get(request);

  final data = response.data;

  if (data == null || !data.containsKey('result')) {
    return;
  }

  final location = data['result']['geometry']['location'];

  if (location == null || location['lat'] == null || location['lng'] == null) {
    return;
  }

  double lat = location['lat'] as double;
  double lng = location['lng'] as double;

  _animatedMapController.centerOnPoint(LatLng(lat, lng), zoom: 16);
  addMarker(LatLng(lat, lng));
  setState(() {
    _posAdded = true;
  });
}

    return Scaffold(
      body: Stack(children: [
        GestureDetector( 
          onTap: () {
            if (_isBottomSheetVisible) { 
              _bottomSheetController.animateTo(
                0.0,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              setState(() {
                _isBottomSheetVisible = false;
              });
            }
          },
          child: buildMap(_animatedMapController, context, _markers, _posAdded, _handlePinTap, _markerMetadata),
        ),

        if (_isBottomSheetVisible)
  Align(
    alignment: Alignment.bottomCenter,
    child: DraggableScrollableSheet(
      controller: _bottomSheetController,
      initialChildSize: 0.1, 
      minChildSize: 0.1, 
      maxChildSize: 0.8, 
      expand: false,
      snap: true, 
      snapSizes: [0.1, 0.3, 0.8], 
      builder: (context, scrollController) {
        return bottom_bar(
          metadata: _selectedMetadata,
          scrollController: scrollController,
        );
      },
    ),
  ),




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
            if (!isFocused)
              {
                setState(() {
                  placesList = [];
                })
              }
          },
          debounceDelay: const Duration(milliseconds: 500),
          onSubmitted: (query) {
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
            } else {
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
                            getLatLng(selectedID!, place.address);
                          });
                    }).toList(),
                  ),
                ),
              );
            }
          },
        )
      ]),
    );
  }
}
