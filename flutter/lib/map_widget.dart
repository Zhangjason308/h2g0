import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_math/flutter_geo_math.dart';
import 'package:geolocator/geolocator.dart';
import 'package:h2g0/models/place.dart';
import 'package:latlong2/latlong.dart';
import 'package:h2g0/models/marker_state.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'bottom_bar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MapWidget extends StatefulWidget {
  final String? placesAPIKey;
  final String? graphapikey;
  final List washroomLocations;
  final List waterFountainLocations;

  const MapWidget({
    super.key,
    required this.placesAPIKey,
    required this.graphapikey,
    required this.washroomLocations,
    required this.waterFountainLocations,
  });

  @override
  State<MapWidget> createState() => _MapWidget();
}

Widget buildMap(
  AnimatedMapController mapcontroller,
  BuildContext context,
  List<Marker> markers,
  List<Polyline> polylines,
  bool posAdded,
  MarkerState? selectedMarker, 
  StreamController<double?> alignposstream, 
  AlignOnUpdate alignonupdate,
  Function(Map<String, dynamic>) onPinTap,
  Map<LatLng, Map<String, dynamic>> markerMetadata,
) {

  return FlutterMap(
    mapController: mapcontroller.mapController,
    options: MapOptions(
      initialCenter: LatLng(45.424721, -75.695000),
      initialZoom: 14,
    ),
    children: [
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.h2g0.app',
        tileProvider: CancellableNetworkTileProvider(),
      ),
      MarkerLayer(
        markers: markers,
        rotate: true,
      ),
      PolylineLayer(
        polylines: polylines,
      ),
      CurrentLocationLayer(
        alignPositionStream: alignposstream.stream,
        alignPositionOnUpdate: alignonupdate,
      ),
      
      RichAttributionWidget(
        alignment: AttributionAlignment.bottomLeft,
        attributions: [
          TextSourceAttribution(
            'OpenStreetMap contributors',
            onTap: () => launchUrl(
              Uri.parse('https://openstreetmap.org/copyright'),
            ),
          ),
        ],
      ),
    ],
  );
}

enum SelectedFacilitiy {WASHROOM, FOUNTAIN}

class _MapWidget extends State<MapWidget> with TickerProviderStateMixin {
  final _controller = FloatingSearchBarController();
  final DraggableScrollableController _bottomSheetController = DraggableScrollableController();
  final Map<LatLng, Map<String, dynamic>> _markerMetadata = {};
  final List<Marker> _markers = [];
  final List<Polyline> _polylines = [];
  late AlignOnUpdate _alignPositionOnUpdate;
  late final StreamController<double?> _alignPositionStreamController;

  List<Place> placesList = [];
  Map<String, dynamic> _selectedMetadata = {
    'name': 'Select a location',
    'address': 'Tap a marker to see details',
  };

  bool _isBottomSheetVisible = false;
  bool _posAdded = false;
  MarkerState? _selectedMarker;
  List<Marker> _filteredmarkers = [];
  List<dynamic> filters = [false, false, false, false, false, false, 0];

  late final _animatedMapController = AnimatedMapController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
    curve: Curves.easeInOutSine,
    cancelPreviousAnimations: true,
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
    _alignPositionOnUpdate = AlignOnUpdate.once;
    _alignPositionStreamController = StreamController<double?>();

    _markers.clear();
    _filteredmarkers.clear();
    int mark = 0;
    for (var location in widget.washroomLocations) {
      double lat = double.tryParse(location['Y_COORDINATE'].toString()) ?? 0.0;
      double lng = double.tryParse(location['X_COORDINATE'].toString()) ?? 0.0;
      int listposition = mark;

      LatLng position = LatLng(lat, lng);
      Map<String, dynamic> metadata = {
        'name': location['NAME'],
        'address': location['ADDRESS'],
        'telephone': location['REPORT_TELEPHONE'],
        'accessibility': location['ACCESSIBILITY'],
        'changestationchild': location['CHANGE_STATION_CHILD'],
        'changestationadult': location['CHANGE_STATION_ADULT'],
        'familytoilet': location['FAMILY_TOILET'],
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
        MarkerState(
          width: 40,
          height: 40,
          listPos: listposition,
          metadata: metadata,
          facilityType: Type.WASHROOM,
          point: position,
          child: GestureDetector(
            onTap: () => selectedAMarker(_filteredmarkers[listposition]),
            child: Image.asset(
              'assets/images/ToiletIcon_final.png',
              width: 40,
              height: 54,
              color: Colors.blue,
              alignment: FractionalOffset(0, 27),
            ),
          ),
        ),
      );
      mark ++;
    }

    for (var location in widget.waterFountainLocations) {
      double lat = double.tryParse(location['Y_COORDINATE'].toString()) ?? 0.0;
      double lng = double.tryParse(location['X_COORDINATE'].toString()) ?? 0.0;
      int listposition = mark;

      LatLng position = LatLng(lat, lng);
      Map<String, dynamic> metadata = {
        'name': location['BUILDING_NAME'],
        'address': location['ADDRESS'],
        'hours': location['HOURS_OF_OPERATION'],
        'inout': location['INSIDE_OUTSIDE'],
        'yearround': location['OPEN_YEAR_ROUND']
      };

      _markerMetadata[position] = metadata;

      _markers.add(
        MarkerState(
          width: 40,
          height: 40,
          listPos: listposition,
          metadata: metadata,
          facilityType: Type.FOUNTAIN,
          point: position,
          child: GestureDetector(
            onTap: () => selectedAMarker(_filteredmarkers[listposition]),
            child: Image.asset(
              'assets/images/FountainIcon_final.png',
              width: 40,
              height: 54,
              color: Colors.blue,
              alignment: FractionalOffset(0, 27),
            ),
          ),
        ),
      );
      mark ++;
    }
    viewWashrooms();
  }

  // Functions
  
  void selectedAMarker(Marker marker) {
    MarkerState mark = marker as MarkerState;
    int index = _filteredmarkers.indexOf(marker);
    MarkerState? previousMarker = _selectedMarker;

    MarkerState updatedMarker = MarkerState(
      width: 40,
      height: 40,
      facilityType: mark.facilityType,
      point: mark.point, 
      child: (mark.facilityType == Type.WASHROOM)
        ? Image.asset(
              'assets/images/ToiletIcon_final.png',
              width: 40,
              height: 54,
              color: Colors.red,
              alignment: FractionalOffset(0, 27),
            )
        : Image.asset(
              'assets/images/FountainIcon_final.png',
              width: 40,
              height: 54,
              color: Colors.red,
              alignment: FractionalOffset(0, 27),
            ), 
      metadata: mark.metadata, 
      listPos: index);

    setState(() {
      _selectedMarker = mark;
      _filteredmarkers[updatedMarker.listPos] = updatedMarker;
      if (previousMarker != null) {
        print(previousMarker.facilityType);
        MarkerState returnMarker = MarkerState(
          width: 40,
          height: 40,
          facilityType: previousMarker.facilityType,
          metadata: previousMarker.metadata,
          listPos: previousMarker.listPos,
          point: previousMarker.point,
          child: GestureDetector(
            onTap: () {
              selectedAMarker(_filteredmarkers[previousMarker.listPos]);
            },
            child: (previousMarker.facilityType == Type.WASHROOM)
              ? Image.asset(
                'assets/images/ToiletIcon_final.png',
                width: 40,
                height: 54,
                color: Colors.blue,
                alignment: FractionalOffset(0, 27),
              )
              : Image.asset(
                'assets/images/FountainIcon_final.png',
                width: 40,
                height: 54,
                color: Colors.blue,
                alignment: FractionalOffset(0, 27),
              ),
          )
        );

        _filteredmarkers[previousMarker.listPos] = returnMarker;
      }
    });
    if (!kIsWeb) _handlePinTap(mark.metadata);
  }

  void clearSelectedMarker() {
    setState(() {
      if (_selectedMarker != null)
      {
        _filteredmarkers[_selectedMarker!.listPos] = MarkerState(
            width: 40,
            height: 40,
            facilityType: Type.WASHROOM,
            metadata: _selectedMarker!.metadata,
            listPos: _selectedMarker!.listPos,
            point: _selectedMarker!.point,
            child: GestureDetector(
              onTap: () {
                selectedAMarker(_filteredmarkers[_selectedMarker!.listPos]);
              },
              child: (_selectedMarker!.facilityType == Type.WASHROOM)
              ? Image.asset(
                'assets/images/ToiletIcon_final.png',
                width: 40,
                height: 54,
                color: Colors.blue,
                alignment: FractionalOffset(0, 27),
              )
              : Image.asset(
                'assets/images/FountainIcon_final.png',
                width: 40,
                height: 54,
                color: Colors.blue,
                alignment: FractionalOffset(0, 27),
              ),
            )
          );
          _selectedMarker = null;
      }      
    });
  }

  void addMarker(LatLng coordinates) {
    if (_posAdded) {
      _filteredmarkers.removeLast();
    }

    _markerMetadata[coordinates] = {
      'name': 'Searched Location',
      'address': 'Searched Address'
    };

    _filteredmarkers.add(
      Marker(
        width: 40,
        height: 40,
        point: coordinates,
        child: GestureDetector(
          onTap: () => _handlePinTap(_markerMetadata[coordinates]!),
          child: const Icon(
            Icons.location_pin,
            color: Colors.red,
            size: 40,
          ),
        ),
      ),
    );

    setState(() => _posAdded = true);
  }

  void getDirections(LatLng source, LatLng destination) async {
    String baseURL = "https://graphhopper.com/api/1/route";
    String sourcePos = "${source.latitude},${source.longitude}";
    String destinationPos = "${destination.latitude},${destination.longitude}";
    String? key = widget.graphapikey;

    String request = '$baseURL?profile=foot&point=$sourcePos&point=$destinationPos&locale=en&points_encoded=false&key=$key';
    Response response = await Dio().get(request);
    List<dynamic> points = response.data['paths'][0]['points']['coordinates'];
    List<LatLng> coords = [];
    for (dynamic cord in points) {
      coords.add(LatLng(cord[1], cord[0]));
    }
    setState(() {
      _polylines.clear();

      _polylines.add(
        Polyline(
          points: coords,
          color: Colors.red,
          strokeWidth: 5.0
        )
      );
    });
  }

  Future<LatLng> getLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
    return LatLng(position.latitude, position.longitude);
  }

  void getResults(String input) async {
    String baseURL =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    String type = 'geocode';
    String location = '45.424721\%2C-75.695000';
    String radius = '50000';
    input = input.replaceAll(" ", "\%2C");
    String? apiKey = widget.placesAPIKey;
    //TODO Add session token

    String request =
        '$baseURL?input=$input&key=$apiKey&type=$type&location=$location&radius=$radius&strictbounds=true';

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
    String? apiKey = widget.placesAPIKey;

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

  void viewWashrooms() { // Make only washroom markers visible
    setState(() {
        List<Marker> tempMarkers = List<Marker>.from(_markers);
        tempMarkers = tempMarkers.where((marker) => (marker as MarkerState).facilityType == Type.WASHROOM).toList();
        _filteredmarkers.clear();
        for (int i = 0; i < tempMarkers.length; i++) {
          int loc = i;
          _filteredmarkers.add(
            MarkerState(
              width: 40,
              height: 40,
              facilityType: Type.WASHROOM,
              metadata: (tempMarkers[loc] as MarkerState).metadata,
              listPos: loc,
              point: tempMarkers[loc].point,
              child: GestureDetector(
                onTap: () {
                  selectedAMarker(_filteredmarkers[loc]);
                },
                child: Image.asset(
                  'assets/images/ToiletIcon_final.png',
                  width: 40,
                  height: 54,
                  color: Colors.blue,
                  alignment: FractionalOffset(0, 27),
                )
              )
            ),
          );
        }
        _selectedMarker = null;
      }
    );
  }

  void viewFountains() {
    setState(() {
        List<Marker> tempMarkers = List<Marker>.from(_markers);
        tempMarkers = tempMarkers.where((marker) => (marker as MarkerState).facilityType == Type.FOUNTAIN).toList();
        _filteredmarkers.clear();
        for (int i = 0; i < tempMarkers.length; i++) {
          int loc = i;
          _filteredmarkers.add(
            MarkerState(
              width: 40,
              height: 40,
              facilityType: Type.FOUNTAIN,
              metadata: (tempMarkers[loc] as MarkerState).metadata,
              listPos: loc,
              point: tempMarkers[loc].point,
              child: GestureDetector(
                onTap: () {
                  selectedAMarker(_filteredmarkers[loc]);
                },
                child: Image.asset(
                  'assets/images/FountainIcon_final.png',
                  width: 40,
                  height: 54,
                  color: Colors.blue,
                  alignment: FractionalOffset(0, 27),
                )
              )
            ),
          );
        }
        _selectedMarker = null;
      }
    );
  }

  void applyFilters(SelectedFacilitiy? facilityType) async {
    if (facilityType == SelectedFacilitiy.WASHROOM)
    {
      viewWashrooms();
      if (filters[0]) _filteredmarkers = _filteredmarkers.where((marker) => (marker as MarkerState).metadata['changestationchild'] == "1").toList();
      if (filters[2]) _filteredmarkers = _filteredmarkers.where((marker) => (marker as MarkerState).metadata['changestationadult'] == "1").toList();
      if (filters[3]) _filteredmarkers = _filteredmarkers.where((marker) => (marker as MarkerState).metadata['familytoilet'] == "1").toList();
    }
    else if (facilityType == SelectedFacilitiy.FOUNTAIN) {

    }

    //Distance
    bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();

    getLocation().then((value) {
      if (filters[6] != 0 && isLocationEnabled) _filteredmarkers = _filteredmarkers.where((marker) => (distance(value, (marker as MarkerState).point) <= filters[6]*1000)).toList();
    });
    
  }

  void closeBottomSheet() {
    _bottomSheetController.animateTo(0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut);
    setState(() => _isBottomSheetVisible = false);
  }

  void clearDirections() {
    setState(() {
      _polylines.clear();
    });
  }

  void generateDirectionTile(String distance, String name, String direction) 
  {
  }

  double distance(LatLng point1, LatLng point2)
  {
    double dist(FlutterMapMath l) => l.distanceBetween(point1.latitude, point1.longitude, point2.latitude, point2.longitude, "meters");
    return dist as double;
  }

  SelectedFacilitiy? facility = SelectedFacilitiy.WASHROOM;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    String? selectedID;
    
    return Scaffold(
      drawer: Drawer(
        width: (kIsWeb) ? 500 : 300,
        child: DefaultTabController(
          length: (kIsWeb) ? 2 : 1, 
          child: Scaffold(
            appBar: AppBar( 
              bottom: const TabBar (
                tabs: [
                  Tab(icon: Icon(Icons.filter_alt), text: "Filter"),
                  if (kIsWeb) Tab(icon: Icon(Icons.location_on))
                ],
            )
            ),
            body: TabBarView(
              children: [
                ListView(
                  // Important: Remove any padding from the ListView.
                  padding: EdgeInsets.zero,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("Type"),
                    ),
                    RadioListTile<SelectedFacilitiy>(
                      title: const Text('Washroom'),
                      value: SelectedFacilitiy.WASHROOM,
                      groupValue: facility,
                      onChanged: (SelectedFacilitiy? value) {
                        print(facility);
                        viewWashrooms();
                        if(!kIsWeb && _isBottomSheetVisible) closeBottomSheet();
                        setState(() {
                          facility = value;
                        });
                      },
                    ),
                    RadioListTile<SelectedFacilitiy>(
                      title: const Text('Water Fountain'),
                      value: SelectedFacilitiy.FOUNTAIN,
                      groupValue: facility,
                      onChanged: (SelectedFacilitiy? value) {
                        print(facility);
                        viewFountains();
                        if(!kIsWeb && _isBottomSheetVisible) closeBottomSheet();
                        setState(() {
                          facility = value;
                        });
                        print(facility);
                      },
                    ),
                    Divider(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("Features"),
                    ),
                    if (facility == SelectedFacilitiy.WASHROOM) CheckboxListTile(value: filters[0], onChanged: (bool? value) {setState((){filters[0] = value!;});}, title: Text('Child Change Station')),
                    if (facility == SelectedFacilitiy.WASHROOM) CheckboxListTile(value: filters[1], onChanged: (bool? value) {setState((){filters[1] = value!;});}, title: Text('Adult Change Station')),
                    if (facility == SelectedFacilitiy.WASHROOM) CheckboxListTile(value: filters[2], onChanged: (bool? value) {setState((){filters[2] = value!;});}, title: Text('Family R')),
                    //if (_facility == SelectedFacilitiy.WASHROOM) CheckboxListTile(value: filters[3], onChanged: (bool? value) {filters[3] = value!;}),
                    if (facility == SelectedFacilitiy.FOUNTAIN) CheckboxListTile(value: filters[4], onChanged: (bool? value) {setState((){filters[4] = value!;});}, title: Text('Inside')),
                    if (facility == SelectedFacilitiy.FOUNTAIN) CheckboxListTile(value: filters[5], onChanged: (bool? value) {setState((){filters[5] = value!;});}, title: Text('Open Year Round')),
                    Divider(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("Distance (km)"),
                    ),
                    Slider(
                      value: filters[6],
                      max: 50,
                      divisions: 20,
                      label: filters[6].round().toString(),
                      onChanged: (double value) {
                        setState(() {
                          filters[6] = value;
                        });
                      },
                    ),
                    Divider(),
                    ElevatedButton(onPressed: () => print("Apply!"), child: Text("Apply"))
                  ],
                ),
                if (kIsWeb) Icon(Icons.directions_walk)
              ]
              )
          )
        )
      ),
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (_isBottomSheetVisible) {
                _bottomSheetController.animateTo(0.0,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut);
                setState(() => _isBottomSheetVisible = false);
              }
            },
            child: buildMap(_animatedMapController, context, _filteredmarkers, _polylines, _posAdded, _selectedMarker, _alignPositionStreamController, _alignPositionOnUpdate, _handlePinTap, _markerMetadata),
          ),

          if (_isBottomSheetVisible && !kIsWeb)
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
                    onDirections: () {
                      getLocation().then((value) {
                        getDirections(value, _selectedMarker!.point);
                      });
                    },
                    onClose: () {
                      clearSelectedMarker();
                      clearDirections();
                      closeBottomSheet();
                    },
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
            onFocusChanged: (isFocused) {
              if (!isFocused) setState(() => placesList = []);
            },
            debounceDelay: const Duration(milliseconds: 500),
            onSubmitted: (_) => _controller.close(),
            onQueryChanged: (query) {
              if (query.isNotEmpty) {
                getResults(query);
              } else {
                setState(() => placesList = []);
              }
            },
            transition: CircularFloatingSearchBarTransition(),
            actions: [
              FloatingSearchBarAction(
                showIfOpened: false,
                child: CircularButton(
                  icon: const Icon(Icons.place),
                  onPressed: () {},
                ),
              ),
              FloatingSearchBarAction.searchToClear(showIfClosed: false),
            ],
            builder: (context, transition) {
              if (placesList.isEmpty) return Container();
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
                        },
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: FloatingActionButton(
                backgroundColor: theme.colorScheme.primary,
                onPressed: () {
                // Align the location marker to the center of the map widget
                // on location update until user interact with the map.
                setState(
                  () => _alignPositionOnUpdate = AlignOnUpdate.once,
                );
                // Align the location marker to the center of the map widget
                // and zoom the map to level 18.
                _alignPositionStreamController.add(16);
              },
                child: Icon(
                  Icons.my_location,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  
  
  
}
