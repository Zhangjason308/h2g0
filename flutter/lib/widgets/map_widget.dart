import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:collection/collection.dart';
import 'package:geolocator/geolocator.dart';
import 'package:h2g0/models/place.dart';
import 'package:latlong2/latlong.dart';
import 'package:h2g0/models/marker_state.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'bottom_bar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MapWidget extends StatefulWidget {
  final String? placesAPIKey;
  final String? graphapikey;
  final List washroomLocations;
  final List waterFountainLocations;
  final List artsCultureLocations;

  const MapWidget({
    super.key,
    required this.placesAPIKey,
    required this.graphapikey,
    required this.washroomLocations,
    required this.waterFountainLocations,
    required this.artsCultureLocations
  });

  @override
  State<MapWidget> createState() => _MapWidget();
}

Widget buildMap(
  AnimatedMapController mapcontroller,
  BuildContext context,
  List<Marker> markers,
  List<Polyline> polylines,
  List<CircleMarker> circles,
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
      CircleLayer(
        circles: circles
      ),
      PolylineLayer(
        polylines: polylines,
      ),
      MarkerLayer(
        markers: markers,
        rotate: true,
      ),
      if (!kIsWeb) CurrentLocationLayer(
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

enum SelectedFacilitiy {WASHROOM, FOUNTAIN, ARTS}
enum FountainLocation {INSIDE, OUTSIDE, EITHER}

class _MapWidget extends State<MapWidget> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _key = GlobalKey();
  final _controller = FloatingSearchBarController();
  final DraggableScrollableController _bottomSheetController = DraggableScrollableController();
  final Map<LatLng, Map<String, dynamic>> _markerMetadata = {};
  final List<Marker> _markers = [];
  final List<Polyline> _polylines = [];
  final List<CircleMarker> _circles = [];
  late AlignOnUpdate _alignPositionOnUpdate;
  late final StreamController<double?> _alignPositionStreamController;
  Map<String, dynamic> navList = {
    'start': null,
    'startname': null,
    'dest': null,
    'destname': null,
    'nav': null
  };

  List<Place> placesList = [];
  Map<String, dynamic> _selectedMetadata = {
    'name': 'Select a location',
    'address': 'Tap a marker to see details',
  };

  bool _isBottomSheetVisible = false;
  bool _posAdded = false;
  LatLng? droppedCoords;
  String? droppedAddress;
  MarkerState? _selectedMarker;
  List<Marker> _filteredmarkers = [];
  List<dynamic> filters = [false, false, false, 0.0, FountainLocation.EITHER, false, 0.0, "All"];
  List<Widget> _directionTiles = [];

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
        'seasonal': location['SEASONAL'],
        'seasonstart': location['SEASON_START'],
        'seasonend': location['SEASON_END'],
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
        'hours monday close': location['HOURS_MONDAY_CLOSED'],
        'hours tuesday close': location['HOURS_TUESDAY_CLOSED'],
        'hours wednesday close': location['HOURS_WEDNESDAY_CLOSED'],
        'hours thursday close': location['HOURS_THURSDAY_CLOSED'],
        'hours friday close': location['HOURS_FRIDAY_CLOSED'],
        'hours saturday close': location['HOURS_SATURDAY_CLOSED'],
        'hours sunday close': location['HOURS_SUNDAY_CLOSED'],
      };

      _markerMetadata[position] = metadata;

      _markers.add(
        MarkerState(
          width: 40,
          height:40,
          listPos: listposition,
          metadata: metadata,
          facilityType: Type.WASHROOM,
          point: position,
          child: GestureDetector(
            onTap: () => selectedAMarker(_filteredmarkers[listposition]),
            child: Image.asset(
              'assets/images/ToiletIcon_final.png',
              width: 40,
              height: 40,
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
        'link': location['URL'],
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
              height: 40,
              
              alignment: FractionalOffset(0, 27),
            ),
          ),
        ),
      );
      mark ++;
    }

    for (var location in widget.artsCultureLocations) {
      double lat = double.tryParse(location['Y_COORDINATE'].toString()) ?? 0.0;
      double lng = double.tryParse(location['X_COORDINATE'].toString()) ?? 0.0;
      int listposition = mark;

      LatLng position = LatLng(lat, lng);
      Map<String, dynamic> metadata = {
        'name': location['BUSINESS_ENTITY_DESC'],
        'address': "${location['ADDRNUM']} ${location['FULLNAME']}",
        'buildingdesc': location['BUILDING_DESC'],
        'buildingtype': location['BUILDING_TYPE'],
        'link': location['LINK'],
      };

      _markerMetadata[position] = metadata;

      _markers.add(
        MarkerState(
          width: 40,
          height: 40,
          listPos: listposition,
          metadata: metadata,
          facilityType: Type.ARTS,
          point: position,
          child: GestureDetector(
            onTap: () => selectedAMarker(_filteredmarkers[listposition]),
            child: Image.asset(
              'assets/images/CommunityCentreIcon.png',
              width: 40,
              height: 40,
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
  
  void clearDroppedPin() {
    if (_posAdded) {
      setState(() {
        _filteredmarkers.removeLast();
        _selectedMarker = null;
        _posAdded = false;
        droppedAddress = null;
        droppedCoords = null;
      });
    }
  }

  void addDroppedPin() {
    if (droppedCoords!=null)
    {
      addMarker(droppedCoords!, droppedAddress!, false);
      setState(() {
        _posAdded = true;
      });
    }
  }

  void selectedAMarker(Marker marker) {
    MarkerState mark = marker as MarkerState;
    bool dontSheet = false;
    int index = _filteredmarkers.indexOf(marker);
    if (mark.metadata['name'] == "Dropped Pin") {
      setState(() {
        _selectedMarker = mark;
        if(kIsWeb) _key.currentState!.openDrawer();
        if (!kIsWeb) _handlePinTap(mark.metadata);
      });
      return;
    }

    MarkerState? previousMarker = _selectedMarker;

    String image = "";

    if (mark.facilityType == Type.WASHROOM) {
        image = 'assets/images/ToiletIcon_final';
    }
    else if (mark.facilityType == Type.FOUNTAIN) {
      image = 'assets/images/FountainIcon_final';
    }
    else {
      image = 'assets/images/CommunityCentreIcon';
    }

    MarkerState updatedMarker = MarkerState(
      width: 50,
      height: 50,
      facilityType: mark.facilityType,
      point: mark.point, 
      child: GestureDetector(
        onTap: () => selectedAMarker(_filteredmarkers[mark.listPos]),
        child: Image.asset(
              "${image}_selected.png",
              width: 40,
              height: 40,
              alignment: FractionalOffset(0, 27),
            )),
      metadata: mark.metadata, 
      listPos: index);

    setState(() {
      _selectedMarker = mark;
      _filteredmarkers[updatedMarker.listPos] = updatedMarker;
      if(kIsWeb) _key.currentState!.openDrawer();
      
      if (previousMarker != null && _selectedMarker?.point == previousMarker.point)
      {
        clearSelectedMarker();
        if (!kIsWeb) closeBottomSheet();
        dontSheet = true;
      }
      else if (previousMarker != null && _selectedMarker != previousMarker && previousMarker.metadata['name'] != "Dropped Pin") {

        if (previousMarker.facilityType == Type.WASHROOM)
        {
          image = 'assets/images/ToiletIcon_final';
        }
        else if (previousMarker.facilityType == Type.FOUNTAIN)
        {
          image = 'assets/images/FountainIcon_final';
        }
        else {
          image = 'assets/images/CommunityCentreIcon';
        }
        
        MarkerState returnMarker = MarkerState(
          width: 50,
          height: 50,
          facilityType: previousMarker.facilityType,
          metadata: previousMarker.metadata,
          listPos: previousMarker.listPos,
          point: previousMarker.point,
          child: GestureDetector(
            onTap: () {
              selectedAMarker(_filteredmarkers[previousMarker.listPos]);
            },
            child: Image.asset(
                "$image.png",
                width: 40,
                height: 40,
                alignment: FractionalOffset(0, 27),
              ),
          )
        );

        _filteredmarkers[previousMarker.listPos] = returnMarker;
      }
    });
    if (!kIsWeb && !dontSheet) _handlePinTap(mark.metadata);
  }

  void clearSelectedMarker() {
    setState(() {
      if (_selectedMarker != null)
      {
        String image = "";

        if (_selectedMarker?.facilityType == Type.WASHROOM)
          {
            image = 'assets/images/ToiletIcon_final';
          }
          else if (_selectedMarker?.facilityType == Type.FOUNTAIN)
          {
            image = 'assets/images/FountainIcon_final';
          }
          else {
            image = 'assets/images/CommunityCentreIcon';
          }
        int listPos = _selectedMarker!.listPos;
        _filteredmarkers[_selectedMarker!.listPos] = MarkerState(
            width: 50,
            height: 50,
            facilityType: _selectedMarker!.facilityType,
            metadata: _selectedMarker!.metadata,
            listPos: _selectedMarker!.listPos,
            point: _selectedMarker!.point,
            child: GestureDetector(
              onTap: () {
                selectedAMarker(_filteredmarkers[listPos]);
              },
              child: Image.asset(
                "$image.png",
                width: 40,
                height: 40,
                
                alignment: FractionalOffset(0, 27),
              ),
            )
          );
          _selectedMarker = null;
      }      
    });
  }

  void addMarker(LatLng coordinates, String address, bool removeLast) {
    if (_posAdded && _filteredmarkers.isNotEmpty && removeLast) {
      _filteredmarkers.removeLast();
    }

    Map<String, dynamic> metadata = {
      'name': 'Dropped Pin',
      'address': address
    };

    _filteredmarkers.add(
      MarkerState(
        metadata: metadata,
        listPos: _filteredmarkers.length-1,
        facilityType: Type.COMBO,
        width: 40,
        height: 40,
        point: coordinates,
        child: GestureDetector(
          onTap: () => selectedAMarker(_filteredmarkers[_filteredmarkers.length-1]),
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
  
  void directionPreamble(String dest) {
    _directionTiles.add(
        SizedBox(height: 16,)
      );
      _directionTiles.add(
        ListTile(
          leading: Icon(Icons.location_pin),
          title: Text("Destination: $dest")
        )
      );
      _directionTiles.add(
        SizedBox(height: 16,)
      );
      _directionTiles.add(
        Divider()
      );
      _directionTiles.add(
        SizedBox(height: 16,)
      );
      _directionTiles.add(
        Row(
          children: [
              SizedBox(width: 16,),
              ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 176, 0, 32),
                foregroundColor: Colors.white
              ),
              onPressed: () {
                clearDirections();
                //applyFilters(facility);
                addDroppedPin();
                
                //if (!kIsWeb) closeBottomSheet();
              },
              icon: Icon(Icons.close, color: Colors.white,),
              label: Text("Clear Navigation", ),),
            ],
        ),
      );
      _directionTiles.add(
        SizedBox(height: 16,)
      );
      _directionTiles.add(
        Divider()
      );
      _directionTiles.add(
        SizedBox(height: 16,)
      );
  }

  void pruneDirections(List<dynamic> directions, String dest) {
    _directionTiles.clear();
    setState(() {
      directionPreamble(dest);
      int prevDis = 0;
      for (int i = 0; i < directions.length; i++)
      {
        if (!(directions[i]['street_name'] == "" && !(directions[i]['text'] as String).contains("Arrive")))
        {
          Icon icon = Icon(Icons.check);
          if((directions[i]['text'] as String).contains("sharp left")) {icon = Icon(Icons.turn_sharp_left);}
          else if((directions[i]['text'] as String).contains("slight left")) {icon = Icon(Icons.turn_slight_left);}
          else if((directions[i]['text'] as String).contains("Turn left")) {icon = Icon(Icons.turn_left);}
          else if((directions[i]['text'] as String).contains("sharp left")) {icon = Icon(Icons.turn_sharp_left);}
          else if((directions[i]['text'] as String).contains("slight right")) {icon = Icon(Icons.turn_slight_right);}
          else if((directions[i]['text'] as String).contains("Turn right")) {icon = Icon(Icons.turn_right);}
          else if((directions[i]['text'] as String).contains("sharp right")) {icon = Icon(Icons.turn_sharp_right);}
          else if((directions[i]['text'] as String).contains("Arrive")) {icon = Icon(Icons.check);}
          else {icon = Icon(Icons.arrow_upward);}
          
          _directionTiles.add(
            ListTile(
              leading: icon,
              title: Text("In $prevDis meters, ${directions[i]['text']}"),
              //subtitle: Text(directions[i]['street_name']),
            )
          );
          prevDis = (directions[i]['distance'] as double).toInt();
        }
      }
    });
  }

  void getDirections(LatLng source, LatLng destination, String destname) async {
    String baseURL = "https://graphhopper.com/api/1/route";
    String sourcePos = "${source.latitude},${source.longitude}";
    String destinationPos = "${destination.latitude},${destination.longitude}";
    String? key = widget.graphapikey;

    String request = '$baseURL?profile=bike&point=$sourcePos&point=$destinationPos&locale=en&points_encoded=false&key=$key';
    Response response = await Dio().get(request);
    List<dynamic> points = response.data['paths'][0]['points']['coordinates'];
    pruneDirections(response.data['paths'][0]['instructions'], destname);
    navList['start'] = source;
    navList['dest'] = destination;
    navList['nav'] = _directionTiles;
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
    Position? position = await Geolocator.getLastKnownPosition();
    return LatLng(position!.latitude, position!.longitude);
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
    if (!(await Geolocator.isLocationServiceEnabled()) || kIsWeb)
    {
      addMarker(LatLng(lat, lng), address, true);
      setState(() {
        droppedAddress = address;
        droppedCoords = LatLng(lat, lng);
        _posAdded = true;
      });
    }
    
}

  void viewWashrooms() async {
    List<Marker> tempMarkers = List<Marker>.from(_markers);
    tempMarkers = tempMarkers.where((marker) => (marker as MarkerState).facilityType == Type.WASHROOM).toList(); // Make only washroom markers visible
    setState(() {
      
      _filteredmarkers.clear();
      int mark = 0;
      for (Marker marker in tempMarkers) {
        int loc = mark;
        _filteredmarkers.add(
          MarkerState(
            width: 50,
            height: 50,
            facilityType: Type.WASHROOM,
            metadata: (marker as MarkerState).metadata,
            listPos: loc,
            point: marker.point,
            child: GestureDetector(
              onTap: () {
                selectedAMarker(_filteredmarkers[loc]);
                },
              child: Image.asset(
                'assets/images/ToiletIcon_final.png',
                width: 46,
                height: 62,
                filterQuality: FilterQuality.high,
                colorBlendMode: BlendMode.modulate,
                
                alignment: FractionalOffset(0, 27),
              )
            )
          ),
        );
        mark++;
      }
      _selectedMarker = null;
      if (_posAdded) {
        _posAdded = false;
        addDroppedPin();
      }
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
              width: 50,
              height: 50,
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
                  height: 40,
                  
                  alignment: FractionalOffset(0, 27),
                )
              )
            ),
          );
        }
        _selectedMarker = null;
        if (_posAdded) {
          _posAdded = false;
          addDroppedPin();
        }
      }
    );
  }

  void viewArts() {
    setState(() {
        List<Marker> tempMarkers = List<Marker>.from(_markers);
        tempMarkers = tempMarkers.where((marker) => (marker as MarkerState).facilityType == Type.ARTS).toList();
        _filteredmarkers.clear();
        for (int i = 0; i < tempMarkers.length; i++) {
          int loc = i;
          _filteredmarkers.add(
            MarkerState(
              width: 50,
              height: 50,
              facilityType: Type.ARTS,
              metadata: (tempMarkers[loc] as MarkerState).metadata,
              listPos: loc,
              point: tempMarkers[loc].point,
              child: GestureDetector(
                onTap: () {
                  selectedAMarker(_filteredmarkers[loc]);
                },
                child: Image.asset(
                  'assets/images/CommunityCentreIcon.png',
                  width: 40,
                  height: 40,
                  //
                  alignment: FractionalOffset(0, 27),
                )
              )
            ),
          );
        }
        _selectedMarker = null;
        if (_posAdded) {
          _posAdded = false;
          addDroppedPin();
        }
      }
    );
  }

  double getDistance(LatLng point1, LatLng point2)
  {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((point2.latitude - point1.latitude) * p)/2 +
        c(point1.latitude * p) * c(point2.latitude * p) *
            (1 - c((point2.longitude - point1.longitude) * p))/2;
    var radiusOfEarth = 6371;
    return radiusOfEarth * 2 * asin(sqrt(a)) * 1000;
  }

  void applyFilters(SelectedFacilitiy? facilityType) async {
    
    if (facilityType == SelectedFacilitiy.WASHROOM) {
      viewWashrooms();
    } else if (facilityType == SelectedFacilitiy.FOUNTAIN) {
      viewFountains();
    } else if (facilityType == SelectedFacilitiy.ARTS) viewArts();

    if (_posAdded) {_filteredmarkers.removeLast();}

    setState(() {
      _circles.clear();
    });

    if (DeepCollectionEquality().equals(filters,[false, false, false, 0.0, FountainLocation.EITHER, false, 0.0, "All"])) {
      addDroppedPin();
      return;} // if no filters were applied
    //Distance
    bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    LatLng? position;
    if (isLocationEnabled && !kIsWeb) {
      position = await getLocation();
    }

    setState(() {
    if (facilityType == SelectedFacilitiy.WASHROOM)
    {
      if (filters[0]) _filteredmarkers = _filteredmarkers.where((marker) => (marker as MarkerState).metadata['changestationchild'] == "1").toList();
      if (filters[1]) _filteredmarkers = _filteredmarkers.where((marker) => (marker as MarkerState).metadata['changestationadult'] == "1").toList();
      if (filters[2]) _filteredmarkers = _filteredmarkers.where((marker) => (marker as MarkerState).metadata['familytoilet'] == "1").toList();
      if (filters[3] > 0) {
        _filteredmarkers = _filteredmarkers.where((marker) => (marker as MarkerState).metadata['accessibility'] >= filters[3]).toList();
      }
    }
    else if (facilityType == SelectedFacilitiy.FOUNTAIN) {
      if (filters[4] != FountainLocation.EITHER) {
        _filteredmarkers = _filteredmarkers.where((marker) => (marker as MarkerState).metadata['inout'].toString().toUpperCase() == filters[4].toString().substring(17)).toList();
      }
      if (filters[5]) _filteredmarkers = _filteredmarkers.where((marker) => (marker as MarkerState).metadata['yearround'] == "Yes").toList();
    }
    else if (facilityType == SelectedFacilitiy.ARTS) {
      if (filters[7] != "All") {        
        _filteredmarkers = _filteredmarkers.where((marker) => (marker as MarkerState).metadata['buildingtype'].toString().contains(filters[7].toString())).toList();
      }
    }

    if (filters[6] != 0 && !kIsWeb && isLocationEnabled && position != null) {
        _filteredmarkers = _filteredmarkers.where((marker) => (getDistance(position!, (marker as MarkerState).point) <= filters[6]*1000)).toList();
        _circles.add(
          CircleMarker(point: position!, radius: filters[6]*1000, useRadiusInMeter: true, color: Color.fromARGB(100, 65,107,223))
        );
    }
    if (filters[6] != 0 && kIsWeb && _posAdded) {
      _filteredmarkers = _filteredmarkers.where((marker) => (getDistance(droppedCoords!, (marker as MarkerState).point) <= filters[6]*1000)).toList();
      _circles.add(
          CircleMarker(point: droppedCoords!, radius: filters[6]*1000, useRadiusInMeter: true, color: Color.fromARGB(100, 65,107,223))
        );
    }
    });

    setState(() {
      for (int i = 0; i < _filteredmarkers.length; i++) {
      String image;

      if ((_filteredmarkers[i] as MarkerState).facilityType == Type.WASHROOM)
      {
        image = 'assets/images/ToiletIcon_final.png';
      }
      else if ((_filteredmarkers[i] as MarkerState).facilityType == Type.FOUNTAIN)
      {
        image = 'assets/images/FountainIcon_final.png';
      }
      else {
        image = 'assets/images/CommunityCentreIcon.png';
      }

      int pos = i;
      _filteredmarkers[i] = MarkerState(
        width: 50,
        height: 50,
        point: _filteredmarkers[i].point, 
        child: GestureDetector(
              onTap: () {
                selectedAMarker(_filteredmarkers[pos]);
              },
              child: Image.asset(
                      image,
                      width: 40,
                      height: 40,
                      
                      alignment: FractionalOffset(0, 27),
                    )
            ), 
        metadata: (_filteredmarkers[i] as MarkerState).metadata, 
        listPos: pos, 
        facilityType: (_filteredmarkers[i] as MarkerState).facilityType);
    }
      addDroppedPin();
    });
  }

  void clearFilters(SelectedFacilitiy? facilityType) {
    if (facilityType == SelectedFacilitiy.WASHROOM) {
      viewWashrooms();
    } else if (facilityType == SelectedFacilitiy.FOUNTAIN){
      viewFountains();
    } else if (facilityType == SelectedFacilitiy.ARTS) {
      viewArts();
    }

    setState(() {
      _circles.clear();
      filters = [false, false, false, 0.0, FountainLocation.EITHER, false, 0.0, "All"];
    });
  }

  void closeBottomSheet() {
    _bottomSheetController.animateTo(0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut);
    setState(() => _isBottomSheetVisible = false);
  }

  void clearDirections() {
    navList['start'] = null;
    navList['dest'] = null;
    navList['nav'] = null;
    setState(() {
      _directionTiles.clear();
      _polylines.clear();
    });
  }

  void generateDirectionTile(String distance, String name, String direction) 
  {
  }

  SelectedFacilitiy? facility = SelectedFacilitiy.WASHROOM;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    String? selectedID;
    List<bool> bools = [kIsWeb, _selectedMarker != null, navList['dest']!=null && navList['nav'].isNotEmpty];
    int numTabs = bools.where((x) => x == true).length;
    if (!kIsWeb) numTabs = 1;

    return Scaffold(
      key: _key,
      onDrawerChanged:(isOpened) {
        if (kIsWeb && !isOpened && _polylines.isEmpty && _selectedMarker != null) {
          if (!(_selectedMarker!.metadata['name'] == "Dropped Pin")) clearSelectedMarker();
        }
      },
      drawerScrimColor: Colors.transparent,
      drawer: Drawer(
        width: (kIsWeb) ? 500 : 300,
        child: DefaultTabController(
          initialIndex: (kIsWeb && _selectedMarker != null) ? 1 : 0,
          length: numTabs, 
          child: Scaffold(
            appBar: PreferredSize(
            preferredSize: Size.fromHeight(kToolbarHeight+18),
            child: Container(
              child: SafeArea(
                child: Column(
                  children: <Widget>[
                    //Expanded(child: new Container()),
                    TabBar(
                      tabs: [
                        const Tab(icon: Icon(Icons.filter_alt), text: "Filter"),
                        if (kIsWeb && _selectedMarker != null) const Tab(icon: Icon(Icons.location_on), text: "Selected",),
                        if (kIsWeb && navList['dest']!=null && navList['nav'].isNotEmpty) const Tab(icon: Icon(Icons.directions), text: "Navigation")
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
                        viewFountains();
                        if(!kIsWeb && _isBottomSheetVisible) closeBottomSheet();
                        setState(() {
                          facility = value;
                        });
                      },
                    ),
                    RadioListTile<SelectedFacilitiy>(
                      title: const Text('Arts and Culture'),
                      value: SelectedFacilitiy.ARTS,
                      groupValue: facility,
                      onChanged: (SelectedFacilitiy? value) {
                        viewArts();
                        if(!kIsWeb && _isBottomSheetVisible) closeBottomSheet();
                        setState(() {
                          facility = value;
                        });
                      },
                    ),
                    Divider(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("Features"),
                    ),
                    if (facility == SelectedFacilitiy.WASHROOM) CheckboxListTile(value: filters[0], onChanged: (bool? value) {setState((){filters[0] = value!;});}, title: Text('Child Change Station')),
                    if (facility == SelectedFacilitiy.WASHROOM) CheckboxListTile(value: filters[1], onChanged: (bool? value) {setState((){filters[1] = value!;});}, title: Text('Adult Change Station')),
                    if (facility == SelectedFacilitiy.WASHROOM) CheckboxListTile(value: filters[2], onChanged: (bool? value) {setState((){filters[2] = value!;});}, title: Text('Family Toilet')),
                    if (facility == SelectedFacilitiy.WASHROOM) Divider(),
                    if (facility == SelectedFacilitiy.WASHROOM) Padding(
                                                                  padding: const EdgeInsets.all(8.0),
                                                                  child: Text("Accessibility Level"),
                                                                ),
                    if (facility == SelectedFacilitiy.WASHROOM) Slider(
                                                                  value: filters[3],
                                                                  max: 3,
                                                                  divisions: 3,
                                                                  label: filters[3].round().toString(),
                                                                  onChanged: (double value) {
                                                                    setState(() {
                                                                      filters[3] = value;
                                                                    });
                                                                  },
                                                                ),

                    //-------------------------------------- Fountains Filters
                    if (facility == SelectedFacilitiy.FOUNTAIN) RadioListTile<FountainLocation>(
                                                                  title: const Text('Inside'),
                                                                  value: FountainLocation.INSIDE,
                                                                  groupValue: filters[4],
                                                                  onChanged: (FountainLocation? value) {
                                                                    setState(() {
                                                                      filters[4] = value;
                                                                    });
                                                                  },
                                                                ),
                    if (facility == SelectedFacilitiy.FOUNTAIN) RadioListTile<FountainLocation>(
                                                                  title: const Text('Outside'),
                                                                  value: FountainLocation.OUTSIDE,
                                                                  groupValue: filters[4],
                                                                  onChanged: (FountainLocation? value) {
                                                                    setState(() {
                                                                      filters[4] = value;
                                                                    });
                                                                  },
                                                                ),
                    if (facility == SelectedFacilitiy.FOUNTAIN) RadioListTile<FountainLocation>(
                                                                  title: const Text('Either'),
                                                                  value: FountainLocation.EITHER,
                                                                  groupValue: filters[4],
                                                                  onChanged: (FountainLocation? value) {
                                                                    setState(() {
                                                                      filters[4] = value;
                                                                    });
                                                                  },
                                                                ),
                    if (facility == SelectedFacilitiy.FOUNTAIN) CheckboxListTile(value: filters[5], onChanged: (bool? value) {setState((){filters[5] = value!;});}, title: Text('Open Year Round')),
                    
                    //---------------------------------------------------- Arts Filters
                    if (facility == SelectedFacilitiy.ARTS) RadioListTile<String>(
                                                                  title: const Text('All'),
                                                                  value: "All",
                                                                  groupValue: filters[7],
                                                                  onChanged: (String? value) {
                                                                    setState(() {
                                                                      filters[7] = value;
                                                                    });
                                                                  },
                                                                ),
                    if (facility == SelectedFacilitiy.ARTS) RadioListTile<String>(
                                                                  title: const Text('Administration Building'),
                                                                  value: "Administration Building",
                                                                  groupValue: filters[7],
                                                                  onChanged: (String? value) {
                                                                    setState(() {
                                                                      filters[7] = value;
                                                                    });
                                                                  },
                                                                ),
                    if (facility == SelectedFacilitiy.ARTS) RadioListTile<String>(
                                                                  title: const Text('Archives'),
                                                                  value: "Archives",
                                                                  groupValue: filters[7],
                                                                  onChanged: (String? value) {
                                                                    setState(() {
                                                                      filters[7] = value;
                                                                    });
                                                                  },
                                                                ),
                    if (facility == SelectedFacilitiy.ARTS) RadioListTile<String>(
                                                                  title: const Text('Community Centre'),
                                                                  value: "Community Centre",
                                                                  groupValue: filters[7],
                                                                  onChanged: (String? value) {
                                                                    setState(() {
                                                                      filters[7] = value;
                                                                    });
                                                                  },
                                                                ),
                    if (facility == SelectedFacilitiy.ARTS) RadioListTile<String>(
                                                                  title: const Text('Cultural Facility'),
                                                                  value: "Cultural Facility",
                                                                  groupValue: filters[7],
                                                                  onChanged: (String? value) {
                                                                    setState(() {
                                                                      filters[7] = value;
                                                                    });
                                                                  },
                                                                ),
                    if (facility == SelectedFacilitiy.ARTS) RadioListTile<String>(
                                                                  title: const Text('Museum'),
                                                                  value: "Museum",
                                                                  groupValue: filters[7],
                                                                  onChanged: (String? value) {
                                                                    setState(() {
                                                                      filters[7] = value;
                                                                    });
                                                                  },
                                                                ),
                    if (facility == SelectedFacilitiy.ARTS) RadioListTile<String>(
                                                                  title: const Text('Performing Arts Facility'),
                                                                  value: "Performing Arts Facility",
                                                                  groupValue: filters[7],
                                                                  onChanged: (String? value) {
                                                                    setState(() {
                                                                      filters[7] = value;
                                                                    });
                                                                  },
                                                                ),
                    if (facility == SelectedFacilitiy.ARTS) RadioListTile<String>(
                                                                  title: const Text('Public Library'),
                                                                  value: "Public Library",
                                                                  groupValue: filters[7],
                                                                  onChanged: (String? value) {
                                                                    setState(() {
                                                                      filters[7] = value;
                                                                    });
                                                                  },
                                                                ),
                    if (facility == SelectedFacilitiy.ARTS) RadioListTile<String>(
                                                                  title: const Text('Recreation Complex'),
                                                                  value: "Recreation Complex",
                                                                  groupValue: filters[7],
                                                                  onChanged: (String? value) {
                                                                    setState(() {
                                                                      filters[7] = value;
                                                                    });
                                                                  },
                                                                ),
                                                                
                    Divider(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("Distance (km)"),
                    ),
                    Slider(
                      value: filters[6],
                      max: 50,
                      divisions: 20,
                      label: filters[6].toStringAsFixed(1),
                      onChanged: (double value) {
                        setState(() {
                          filters[6] = value;
                        });
                      },
                    ),
                    Divider(),
                    Row(
                      
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(onPressed: () => clearFilters(facility), child: Text("Clear Filters")),
                        ),
                        Spacer(),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(onPressed: () => applyFilters(facility), child: Text("Apply Filters")),
                        ),
                      ],
                    )
                  ],
                ),
                if (kIsWeb && _selectedMarker != null) Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [

                      // Title + close button row
                      SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _selectedMarker?.metadata['name'] ?? 'No Name',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  overflow: TextOverflow.fade
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                if (!(_selectedMarker!.metadata['name'] == "Dropped Pin"))
                                {
                                  clearSelectedMarker();
                                  clearDirections();
                                }
                              }, 
                            ),
                          ],
                        ),
                      ),
                            
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          children: [
                            Text(_selectedMarker?.metadata['address'] ?? 'No Address', textAlign: TextAlign.left),
                            if (_selectedMarker?.metadata['telephone'] != null)
                            Text('Telephone: ${_selectedMarker?.metadata['telephone']}', textAlign: TextAlign.left),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                if (_selectedMarker!.metadata['name'] != "Dropped Pin" && navList['dest']!=_selectedMarker?.point) ElevatedButton.icon(
                                onPressed: () {
                                    if (!kIsWeb) {
                                      getLocation().then((value) {
                                      getDirections(value, _selectedMarker!.point, _selectedMarker!.metadata['name']);
                                    });
                                    }
                                    else {
                                      if (_posAdded) {
                                        getDirections(droppedCoords!, _selectedMarker!.point, _selectedMarker!.metadata['name']);
                                        
                                      }
                                      else {
                                        showDialog<String>(
                                          context: context,
                                          builder:
                                              (BuildContext context) => AlertDialog(
                                                title: const Text('No Pin!'),
                                                content: const Text('You have no dropped pins to navigate from!\nSearch to drop a pin!'),
                                                actions: <Widget>[
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, 'Cancel'),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, 'OK'),
                                                    child: const Text('OK'),
                                                  ),
                                                ],
                                              ),
                                        );
                                      }
                                    }
                                },
                                icon: Icon(Icons.directions),
                                label: Text("Directions"),
                                ),

                                if (_selectedMarker!.metadata['name'] != "Dropped Pin" && navList['dest']==_selectedMarker?.point) ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color.fromARGB(255, 176, 0, 32),
                                    foregroundColor: Colors.white
                                  ),
                                onPressed: () {
                                  clearDirections();
                                  applyFilters(facility);
                                  addDroppedPin();
                                  
                                  //closeBottomSheet();
                                },
                                icon: Icon(Icons.close, color: Colors.white,),
                                label: Text("Clear Navigation", ),),

                                if (_selectedMarker!.metadata['name'] == "Dropped Pin") ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color.fromARGB(255, 176, 0, 32),
                                    foregroundColor: Colors.white
                                  ),
                                onPressed: () {
                                  clearDroppedPin();
                                  clearDirections();
                                  applyFilters(facility);
                                  //closeBottomSheet();
                                },
                                icon: Icon(Icons.close, color: Colors.white,),
                                label: Text("Remove Pin", ),),
                                ]
                    
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            if (_selectedMarker?.facilityType==Type.WASHROOM)Text("Season", style: TextStyle(fontSize: 18)),
                            if (_selectedMarker?.facilityType==Type.WASHROOM) SizedBox(height: 16),
                            if (_selectedMarker?.facilityType==Type.WASHROOM && _selectedMarker?.metadata['seasonal'] == '0') Text("${' ' * 5} Open Year Round"),
                            if (_selectedMarker?.facilityType==Type.WASHROOM && _selectedMarker?.metadata['seasonal'] == '1') Text("${' ' * 5} Open From ${_selectedMarker?.metadata['seasonstart']} to ${_selectedMarker?.metadata['seasonend']}"),
                            const SizedBox(height: 16),
                            if (_selectedMarker?.facilityType==Type.WASHROOM) Divider(),
                            if (_selectedMarker?.facilityType==Type.WASHROOM)Text("Hours of Operation", style: TextStyle(fontSize: 18)),
                            if (_selectedMarker?.facilityType==Type.WASHROOM) SizedBox(height: 16),
                            for (var day in [
                              'monday',
                              'tuesday',
                              'wednesday',
                              'thursday',
                              'friday',
                              'saturday',
                              'sunday'
                            ])
                              if (_selectedMarker?.metadata['hours $day open'] != null)
                                Text('${' ' * 5} ${day[0].toUpperCase()}${day.substring(1)}: ${_selectedMarker?.metadata['hours $day open']} to ${_selectedMarker?.metadata['hours $day close']}'),
                            
                            if (_selectedMarker?.metadata['hours'] != null) Text('Hours: ${_selectedMarker?.metadata['hours']}', style: TextStyle(fontSize: 16)),
                            if (_selectedMarker?.metadata['inout'] != null) Text('Inside or Outside?: ${_selectedMarker?.metadata['inout']}', style: TextStyle(fontSize: 16)),
                            if (_selectedMarker?.metadata['yearround'] != null) Text('Year Round?: ${_selectedMarker?.metadata['yearround']}', style: TextStyle(fontSize: 16)),
                            if (_selectedMarker?.metadata['buildingtype'] != null) Text('Type: ${_selectedMarker?.metadata['buildingtype']}', style: TextStyle(fontSize: 16)),
                            if (_selectedMarker?.metadata['buildingdesc'] != null) Text('${_selectedMarker?.metadata['buildingdesc']}', style: TextStyle(fontSize: 16)),
                            if (_selectedMarker?.facilityType == Type.FOUNTAIN) SizedBox(height: 16),
                            if (_selectedMarker?.facilityType != Type.WASHROOM && _selectedMarker?.metadata['link'] != null) Row(
                              children: [
                                ElevatedButton.icon(onPressed: () => launchUrlString(_selectedMarker?.metadata['link']), icon: Icon(Icons.info), label: Text("More Info"),),
                              ],
                            ),
                            
                            
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (kIsWeb && navList['dest']!=null) Container(
                  child: ListView(
                    children: navList['nav'],
                  )
                )
              ]
              )
          )
        )
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              
              if (_isBottomSheetVisible) {
                _bottomSheetController.animateTo(0.0,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut);
                setState(() => _isBottomSheetVisible = false);
              }
            },
            child: buildMap(_animatedMapController, context, _filteredmarkers, _polylines, _circles, _posAdded, _selectedMarker, _alignPositionStreamController, _alignPositionOnUpdate, _handlePinTap, _markerMetadata),
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
                snapSizes: [0.2, 0.3, 0.8],
                builder: (context, scrollController) {
                  return bottom_bar(
                    metadata: _selectedMetadata,
                    type: _selectedMarker?.facilityType,
                    scrollController: scrollController,
                    navList: navList,
                    onDirections: () async {
                      if (await Geolocator.isLocationServiceEnabled()) {
                        getLocation().then((value) {
                        getDirections(value, _selectedMarker!.point, _selectedMarker!.metadata['name']);
                      }); 
                      }
                    },
                    onClose: () {
                      if (!(_selectedMarker!.metadata['name'] == "Dropped Pin"))
                      {
                        clearSelectedMarker();
                        clearDirections();
                      }
                      closeBottomSheet();
                    },
                    removeDropped: () {
                      clearDroppedPin();
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
                          clearDirections();
                          clearSelectedMarker();
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
