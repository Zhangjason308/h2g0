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

  const MapWidget({
    super.key,
    required this.placesAPIKey,
    required this.washroomLocations,
  });

  @override
  State<MapWidget> createState() => _MapWidget();
}

class _MapWidget extends State<MapWidget> with TickerProviderStateMixin {
  final Map<LatLng, Map<String, dynamic>> _markerMetadata = {};
  final _controller = FloatingSearchBarController();
  List<Place> placesList = [];
  final List<Marker> _markers = [];
  bool _posAdded = false;
  bool _isBottomSheetVisible = false;

  final DraggableScrollableController _bottomSheetController = DraggableScrollableController();

  Map<String, dynamic> _selectedMetadata = {
    'name': 'Select a location',
    'address': 'Tap a marker to see details',
  };

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
  void initState() {
    super.initState();

    _markers.clear();
    for (var location in widget.washroomLocations) {
      double lat = double.tryParse(location['Y_COORDINATE'].toString()) ?? 0.0;
      double lng = double.tryParse(location['X_COORDINATE'].toString()) ?? 0.0;

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
              Icons.wc,
              color: Colors.blue,
              size: 40,
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _bottomSheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      body: Stack(
        children: [
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
                initialChildSize: 0.3,
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
        ],
      ),
    );
  }
}

Widget buildMap(
  AnimatedMapController mapController,
  BuildContext context,
  List<Marker> markers,
  bool posAdded,
  Function(Map<String, dynamic>) onPinTap,
  Map<LatLng, Map<String, dynamic>> markerMetadata,
) {
  return FlutterMap(
    mapController: mapController.mapController,
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
      MarkerLayer(markers: markers),
      CurrentLocationLayer(
        alignPositionOnUpdate: AlignOnUpdate.always,
        alignDirectionOnUpdate: AlignOnUpdate.never,
      ),
      Align(
        alignment: Alignment.bottomRight,
        child: FloatingActionButton(
          backgroundColor: Theme.of(context).colorScheme.primary,
          onPressed: () {
            mapController.centerOnPoint(LatLng(45.424721, -75.695000), zoom: 16);
          },
          child: Icon(Icons.my_location, color: Theme.of(context).colorScheme.onPrimary),
        ),
      ),
    ],
  );
}
